import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import '../../widgets/GuessCoverImage.dart';
import '../../widgets/GuessGameStatusPanel.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/utils/CommonWidgetUtil.dart';
import 'package:flutter/services.dart';
import 'package:my_first_flutter_app/entity/GuessChartGame/GuessSong.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/manager/SongAliasManager.dart';
import 'package:my_first_flutter_app/service/SongSearchService.dart';
import 'package:my_first_flutter_app/service/GuessChartGame/GuessChartByAliaService.dart';
import 'package:my_first_flutter_app/service/GuessChartGame/GuessChartCommonSettingsService.dart';
import 'package:my_first_flutter_app/utils/CommonCacheUtil.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/utils/SongFilterUtil.dart';
import '../../utils/AppTheme.dart';
import '../../utils/ExternalLaunchUtil.dart';
import 'package:my_first_flutter_app/page/SongInfoPage.dart';
import 'package:my_first_flutter_app/page/GuessChartGame/GuessChartLoadingView.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/GuessUi.dart';
import '../../utils/AppDesignTokens.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/GuessSettingsUi.dart';

class GuessChartByAliaPage extends StatefulWidget {
  const GuessChartByAliaPage({super.key});

  @override
  State<GuessChartByAliaPage> createState() => _GuessChartByAliaPageState();
}

class _GuessChartByAliaPageState extends State<GuessChartByAliaPage> {
  // 游戏状态
  bool _isGameStarted = false;
  Song? _targetSong;
  String? _targetAlias;
  List<GuessSong> _guessHistory = [];
  int _guessCount = 0;
  int _maxGuesses = 10; // 从设置中加载
  int _timeLimit = 0; // 从设置中加载，0表示无限制
  bool _isGameOver = false;
  bool _isWon = false;
  String _loadFailureMessage = ''; // 开局取曲失败时的提示（空 = 加载中/没失败）

  // 倒计时相关
  int _remainingTime = 0;
  Timer? _countdownTimer;

  // 搜索状态
  TextEditingController _searchController = TextEditingController();
  List<Song> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchTimer;
  int _searchGeneration = 0;
  static const Duration _searchDelay = Duration(milliseconds: 800);
  bool _showSearchResults = false;

  // 排序状态
  bool _isAscending = true; // true: 顺序, false: 逆序

  // 设置相关
  List<String> _selectedVersions = [];
  double _masterMinDx = 1.0;
  double _masterMaxDx = 15.0;
  List<String> _selectedGenres = [];
  late GuessChartCommonSettingsService _settingsService;

  // 歌曲别名管理器
  late SongAliasManager _songAliasManager;

  // 统计数据
  Map<String, dynamic> _stats = {
    'correct': 0,
    'wrong': 0,
    'accuracy': 0.0,
    'avgTime': 0.0,
  };

  // 缓存工具
  final _cacheUtil = CommonCacheUtil();

  // 游戏时间记录
  DateTime? _gameStartTime;
  bool _resultRecorded = false;
  int _statsGeneration = 0;

  @override
  void initState() {
    super.initState();
    _songAliasManager = SongAliasManager.instance;
    _settingsService = GuessChartCommonSettingsService();
    _loadSettings();
    _initCache();
    _initGame();
  }

  // 初始化缓存
  Future<void> _initCache() async {
    await _cacheUtil.initCache('4');
    await _loadStats();
  }

  // 加载统计数据
  Future<void> _loadStats() async {
    final generation = ++_statsGeneration;
    final stats = await _cacheUtil.getStats('4');
    if (!mounted || generation != _statsGeneration) return;
    setState(() => _stats = Map.from(stats));
  }

  // 重置并刷新统计数据
  Future<void> _resetAndRefreshStats() async {
    final generation = ++_statsGeneration;
    await _cacheUtil.resetStats('4', onUpdated: (stats) {
      if (!mounted || generation != _statsGeneration) return;
      setState(() => _stats = Map.from(stats));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // 加载设置
  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    if (!mounted) return;
    setState(() {
      _selectedVersions = settings['selectedVersions'] ?? [];
      _masterMinDx = settings['masterMinDx'] ?? 1.0;
      _masterMaxDx = settings['masterMaxDx'] ?? 15.0;
      _selectedGenres = settings['selectedGenres'] ?? [];
      _maxGuesses = settings['maxGuesses'] ?? 10;
      _timeLimit = settings['timeLimit'] ?? 0;
    });
  }

  // 初始化游戏
  Future<void> _initGame() async {
    await _songAliasManager.init();
    await _startNewGame();
  }

  // 开始新游戏
  Future<void> _startNewGame() async {
    _searchTimer?.cancel();
    _searchGeneration++;
    // 取消之前的倒计时
    _countdownTimer?.cancel();

    // 加载最新的设置
    await _loadSettings();
    if (!mounted) return;

    setState(() {
      _isGameStarted = false;
      _isGameOver = false;
      _isWon = false;
      _loadFailureMessage = '';
      _guessHistory = [];
      _guessCount = 0;
      _searchController.clear();
      _searchResults = [];
      _showSearchResults = false;
      _isSearching = false;
      _remainingTime = _timeLimit; // 重置倒计时
      _resultRecorded = false;
      _gameStartTime = DateTime.now(); // 记录游戏开始时间
    });

    // 随机选择目标歌曲（使用设置的筛选条件）
    _targetSong = await GuessChartByAliaService.randomSelectSong(
      selectedVersions: _selectedVersions,
      masterMinDx: _masterMinDx,
      masterMaxDx: _masterMaxDx,
      selectedGenres: _selectedGenres,
    );
    if (_targetSong != null) {
      // 获取随机别名
      _targetAlias = GuessChartByAliaService.getRandomAlias(_targetSong!);

      setState(() {
        _isGameStarted = true;
        _loadFailureMessage = '';
      });

      // 启动倒计时
      _startCountdown();
      return;
    }

    // 抽曲失败：**绝不能**就此留在加载态（详见 GuessChartLoadingView 注释）。
    // 原先这里没有 else 分支，曲库缓存为空时页面会永久转圈。
    final libraryEmpty = await GuessChartLoadingView.isSongLibraryEmpty();
    if (!mounted) return;
    setState(() {
      // 与谱面片段猜歌同一思路：照常进入游戏界面，只把题面区换成原因说明。
      // 停在 _isGameStarted == false 的话设置齿轮就点不到，用户只能退出去重进。
      _isGameStarted = true;
      _loadFailureMessage = libraryEmpty
          ? GuessChartLoadingView.emptyLibraryMessage
          : GuessChartLoadingView.filterTooStrictMessage;
    });
  }

  /// 失败态下的「重新拉取曲库」：先把曲库缓存拉回来，再重开一局。
  /// 返回 true 表示这局已经成功进入游戏。
  Future<bool> _retryStartGame() async {
    await GuessChartLoadingView.refreshSongLibrary();
    if (!mounted) return false;
    await _startNewGame();
    return mounted && _targetSong != null;
  }

  /// 失败态下的「打开设置」：弹设置对话框，用户关掉后立刻重开一局。
  ///
  /// 为什么要有它：设置入口（齿轮）长在游戏内容里，抽不到曲时页面停在失败态，
  /// 那句「请在设置中放宽条件」指向的按钮根本点不到，用户只能退出去重进。
  /// 返回 true 表示这局已经成功进入游戏（失败视图会因此被替换掉）。
  Future<bool> _openSettingsAndRestart() async {
    await _showSettingsDialog();
    if (!mounted) return false;
    await _startNewGame();
    return mounted && _targetSong != null;
  }

  // 启动倒计时
  void _startCountdown() {
    if (_timeLimit <= 0) return; // 无时间限制

    // 先取消之前可能存在的倒计时
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_isGameOver) {
          // 游戏已结束，取消倒计时
          _countdownTimer?.cancel();
        } else if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          // 时间到，游戏结束
          _countdownTimer?.cancel();
          _isGameOver = true;
          _isWon = false;
          // 记录失败
          _recordGameResult(false);
        }
      });
    });
  }

  // 处理搜索输入
  void _handleSearchInput(String value) {
    _searchTimer?.cancel();
    final generation = ++_searchGeneration;
    final query = value.trim();
    setState(() {
      _searchResults = [];
      _showSearchResults = false;
      _isSearching = query.isNotEmpty;
    });
    if (query.isEmpty) return;

    _searchTimer = Timer(_searchDelay, () async {
      if (!_isCurrentSearch(generation, query)) return;
      try {
        // 与乐曲查询的常规搜索共用匹配规则，保留全部结果。
        final results = await _searchSongs(query);
        if (!_isCurrentSearch(generation, query)) return;
        setState(() {
          _searchResults = results;
          _showSearchResults = !_isGameOver && _searchResults.isNotEmpty;
          _isSearching = false;
        });
      } catch (e) {
        if (!_isCurrentSearch(generation, query)) return;
        setState(() {
          _isSearching = false;
        });
        debugPrint('单人猜歌搜索失败: $e');
      }
    });
  }

  // 输入变更、清空、新开一局或离页后，不再回填旧搜索结果。
  bool _isCurrentSearch(int generation, String query) =>
      mounted &&
      generation == _searchGeneration &&
      _searchController.text.trim() == query;

  // 计算两个字符串的字符符合数百分比
  double _calculateMatchPercentage(String query, String target) {
    if (target.isEmpty) return 0.0;

    query = query.toLowerCase();
    target = target.toLowerCase();

    int matchCount = 0;
    for (int i = 0; i < query.length; i++) {
      if (target.contains(query[i])) {
        matchCount++;
      }
    }

    return (matchCount / target.length) * 100;
  }

  // 复用常规搜索，并应用本模式的防泄题规则。
  Future<List<Song>> _searchSongs(String query) async {
    final matches =
        await SongSearchService.searchSongs(query, titleOnly: false);
    var results = matches.where((song) => !_isMaidataSong(song)).toList();

    // 保留别名猜歌的防泄题规则：与题目别名字符符合数达到 30% 时剔除答案。
    if (_targetSong != null && _targetAlias != null) {
      final matchPercentage = _calculateMatchPercentage(query, _targetAlias!);
      if (matchPercentage >= 30) {
        results = results.where((song) => song.id != _targetSong!.id).toList();
      }
    }
    return results;
  }

  // 判断是否是从maidata追加的歌曲（cids全为0表示从maidata解析），或union独有的歌曲
  bool _isMaidataSong(Song song) {
    if (song.isExtra) return true;
    if (song.cids.isEmpty) return false;
    return song.cids.every((cid) => cid == 0);
  }

  // 处理猜测
  Future<void> _handleGuess(Song guessedSong) async {
    // 抽不到曲时整页仍然可用（题面区显示原因），但猜是空操作
    if (_isGameOver || _targetSong == null) return;

    // 检查是否已经猜过这首歌
    bool hasGuessed =
        _guessHistory.any((guess) => guess.songId == int.parse(guessedSong.id));
    if (hasGuessed) {
      // 显示提示
      AppToast.show(context.l10n.flowYouAlreadyGuessedThisSong, duration: Duration(seconds: 2), tone: AppToastTone.success);
      // 清空输入框
      _searchController.clear();
      _searchResults = [];
      _showSearchResults = false;
      _isSearching = false;
      return;
    }

    // 构建猜测实体
    var guessSong =
        await GuessChartByAliaService.buildGuessSongEntity(guessedSong);
    // 计算猜测结果
    guessSong = await GuessChartByAliaService.calculateGuessResult(
        guessSong, _targetSong!, Theme.of(context).brightness);

    // 更新猜测历史
    setState(() {
      _guessHistory.add(guessSong);
      _guessCount++;
      _searchController.clear();
      _searchResults = [];
      _showSearchResults = false;
      _isSearching = false;
    });

    // 检查游戏是否结束
    if (guessedSong.basicInfo.title == _targetSong!.basicInfo.title) {
      // 猜对了，游戏结束
      _countdownTimer?.cancel();
      setState(() {
        _isGameOver = true;
        _isWon = true;
      });
      // 记录成功
      await _recordGameResult(true);
    } else if (_maxGuesses > 0 && _guessCount >= _maxGuesses) {
      // 猜测次数用完，游戏结束
      _countdownTimer?.cancel();
      setState(() {
        _isGameOver = true;
        _isWon = false;
      });
      // 记录失败
      await _recordGameResult(false);
    }
  }

  // 记录游戏结果
  Future<void> _recordGameResult(bool isWon) async {
    if (_gameStartTime == null || _resultRecorded) return;
    // 先锁定结算状态，倒计时与提交答案同时完成时也只记一局。
    _resultRecorded = true;
    final gameTime = DateTime.now().difference(_gameStartTime!).inSeconds;
    final generation = ++_statsGeneration;
    await _cacheUtil.recordGameResult(
      '4',
      isWon: isWon,
      timeUsedInSeconds: gameTime,
      onUpdated: (stats) {
        if (!mounted || generation != _statsGeneration) return;
        setState(() => _stats = Map.from(stats));
      },
    );
  }

  // 构建搜索结果项
  Widget _buildSearchResultItem(Song song) {
    // 获取别名
    final aliases = _songAliasManager.aliases[song.title] ?? [];
    String aliasText = aliases.isNotEmpty ? aliases.join('、') : '';

    return GestureDetector(
      onTap: () {
        _handleGuess(song);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: AppColors.readableTableBorder(context))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 方形曲绘
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
                child: GuessCoverImage(songId: song.id, size: 60),
              ),
            ),
            const SizedBox(width: 12),
            // 右侧信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Row(
                    children: [
                      Text(
                        song.type == 'SD' ? 'ST' : song.type,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              song.type == 'SD' ? Colors.blue : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          song.basicInfo.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // 作者
                  Text(
                    song.basicInfo.artist,
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 别名
                  if (aliasText.isNotEmpty)
                    Text(
                      aliasText,
                      style: TextStyle(fontSize: 14, color: Colors.blue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建猜测历史项
  Widget _buildGuessHistoryItem(
      GuessSong guessSong, int index, Song? guessedSong) {
    return GuessHistoryCard(
      key: ValueKey('${guessSong.songId}-$index'),
      guessSong: guessSong,
      index: index,
      targetSongId: _targetSong?.id,
      showBpmHistory: true,
    );
  }

  // 构建信息项


  // 显示规则说明对话框
  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title:  Text(context.l10n.flowHowToPlay),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(context.l10n.flowGreenTheAttributeMatchesTheTargetExactly),
                const SizedBox(height: 8),
                 Text(context.l10n.flowOrangeTheAttributeIsCloseToThe),
                const SizedBox(height: 4),
                 Text(context.l10n.flowBPMDiffersByNoMoreThan20),
                 Text(context.l10n.flowMASTEROrReMASTERDifficultyDiffersBy),
                 Text(context.l10n.flowVersionsAreOneGenerationApartEG),
                const SizedBox(height: 8),
                 Text(context.l10n.flowGrayTheAttributeIsFarFromThe),
                const SizedBox(height: 16),
                 Text(context.l10n.flowArrows),
                const SizedBox(height: 4),
                 Text(context.l10n.flowTargetValueIsHigherThanYourGuess),
                 Text(context.l10n.flowTargetValueIsLowerThanYourGuess),
                const SizedBox(height: 16),
                 Text(context.l10n.flowDesignInspiration2),
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse('https://maimai.yukineko2233.top/');

                    if (!await ExternalLaunchUtil.open(url) &&
                        context.mounted) {
                      await ExternalLaunchUtil.copyFallback(
                        context,
                        url.toString(),
                        message: context.l10n.flowCouldNotOpenThisLinkLinkCopied,
                      );
                    }
                  },
                  child: Text(
                    'https://maimai.yukineko2233.top/',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
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
              child:  Text(context.l10n.featureOK),
            ),
          ],
        );
      },
    );
  }

  /// 后台校验「当前筛选条件是否还能抽到曲」，抽不到就用轻提示提醒。
  ///
  /// 放在保存**之后**异步执行：设置已经落盘、用户也已看到「已保存」，
  /// 这里慢一点不会让人干等。校验意义在于尽早发现「条件过严导致开局空转」，
  /// 而不是阻止保存。
  Future<void> _warnIfNoSongMatches({
    required List<String> selectedVersions,
    required double masterMinDx,
    required double masterMaxDx,
    required List<String> selectedGenres,
  }) async {
    // 先取好 messenger：下面 await 之后再用 context 会踩
    // use_build_context_synchronously
    final messenger = ScaffoldMessenger.of(context);
    // Let the dialog pop animation and the save confirmation render before
    // the full-library validation starts on the UI isolate.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    try {
      final testSong = await GuessChartByAliaService.randomSelectSong(
        selectedVersions: selectedVersions,
        masterMinDx: masterMinDx,
        masterMaxDx: masterMaxDx,
        selectedGenres: selectedGenres,
      );
      if (testSong != null || !mounted) return;
      AppToast.show(context.l10n.flowNoSongsMatchTheseFiltersBroadenYour, duration: Duration(seconds: 4), tone: AppToastTone.warning);
    } catch (e) {
      debugPrint('校验筛选条件失败: $e');
    }
  }

  // 显示设置对话框
  Future<void> _showSettingsDialog() async {
    // 加载最新的设置
    await _loadSettings();

    // 加载所有版本和流派
    final allSongs = await GuessChartByAliaService.loadAllSongs();
    // 可选版本 / 可选流派统一走 SongFilterUtil.selectableFilters：
    // 它先剔除非正曲（SongFilterUtil.isExtra：宴会场 / maidata 追加 / union 独有），
    // 再单独挡掉「宴会场」流派，最后把版本过一遍官方世代白名单并按世代排序。
    // 口径必须与抽曲池一致，否则列表里会出现「勾了也永远抽不到」的选项。
    final SongFilterOptions filterOptions =
        SongFilterUtil.selectableFilters(allSongs ?? const <Song>[]);
    final List<String> allVersions = filterOptions.versions;
    final List<String> allGenres = filterOptions.genres;

    // 临时变量用于存储设置
    List<String> tempSelectedVersions = List.from(_selectedVersions);
    double tempMasterMinDx = _masterMinDx;
    double tempMasterMaxDx = _masterMaxDx;
    List<String> tempSelectedGenres = List.from(_selectedGenres);
    int tempMaxGuesses = _maxGuesses;
    int tempTimeLimit = _timeLimit;

    // 「重置所有设置」用：默认值统一取自设置服务，页面不再手写字面量。
    void applySettingsDefaults() {
      final defaults = _settingsService.defaultSettings();
      tempSelectedVersions =
          List<String>.from(defaults['selectedVersions'] as List);
      tempMasterMinDx = (defaults['masterMinDx'] as num).toDouble();
      tempMasterMaxDx = (defaults['masterMaxDx'] as num).toDouble();
      tempSelectedGenres =
          List<String>.from(defaults['selectedGenres'] as List);
      tempMaxGuesses = defaults['maxGuesses'] as int;
      tempTimeLimit = defaults['timeLimit'] as int;
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title:  Text(context.l10n.flowGameSettings),
          subtitle: context.l10n.flowAppliesFromTheNextGame,
          contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonWidgetUtil.buildGuessChartSettingsWidget(
                      context,
                      allVersions,
                      allGenres,
                      tempSelectedVersions,
                      tempMasterMinDx,
                      tempMasterMaxDx,
                      tempSelectedGenres,
                      tempMaxGuesses,
                      tempTimeLimit,
                      (versions) {
                        setState(() {
                          tempSelectedVersions = versions;
                        });
                      },
                      (min, max) {
                        setState(() {
                          tempMasterMinDx = min;
                          tempMasterMaxDx = max;
                        });
                      },
                      (genres) {
                        setState(() {
                          tempSelectedGenres = genres;
                        });
                      },
                      (guesses) {
                        setState(() {
                          tempMaxGuesses = guesses;
                        });
                      },
                      (time) {
                        setState(() {
                          tempTimeLimit = time;
                        });
                      },
                    ),
                    GuessSettingsResetButton(
                      onPressed: () => setState(applySettingsDefaults),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child:  Text(context.l10n.featureCancel),
            ),
            TextButton(
              onPressed: () async {
                // 在 await 之前取好 Navigator / ScaffoldMessenger
                final navigator = Navigator.of(context);

                // 先落盘并立刻反馈：saveSettings 只要 2ms，而抽曲校验要遍历
                // 整份曲库（冷启动含读盘解析），是秒级操作。原先「先校验、
                // 通过才保存」会让用户点完「确定」干等数秒。校验只用于提示
                // 「这组条件抽不到曲」，不影响该不该保存，故挪到保存之后。
                await _settingsService.saveSettings(
                  selectedVersions: tempSelectedVersions,
                  masterMinDx: tempMasterMinDx,
                  masterMaxDx: tempMasterMaxDx,
                  selectedGenres: tempSelectedGenres,
                  maxGuesses: tempMaxGuesses,
                  timeLimit: tempTimeLimit,
                );

                if (!navigator.mounted) return;
                navigator.pop();
                AppToast.show(context.l10n.flowSettingsSavedTheyApplyFromTheNext,
                    tone: AppToastTone.success);

                _warnIfNoSongMatches(
                  selectedVersions: tempSelectedVersions,
                  masterMinDx: tempMasterMinDx,
                  masterMaxDx: tempMasterMaxDx,
                  selectedGenres: tempSelectedGenres,
                );
              },
              child:  Text(context.l10n.featureOK),
            ),
          ],
        );
      },
    );
  }

  // 显示别名
  Widget _buildAliasDisplay() {
    // 抽不到曲：题面区换成原因说明（整页仍照常可用，搜索框与 5 个按钮都在）
    if (_targetSong == null) {
      return GuessChartNoSongNotice(
        message: _loadFailureMessage,
        height: 140,
      );
    }
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppColors.defaultShadow(Theme.of(context).brightness)],
      ),
      child: Center(
        child: Text(
          _targetAlias ?? context.l10n.flowLoading5,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // 获取屏幕尺寸
    final screenWidth = MediaQuery.of(context).size.width;

    // 自定义常量

    return BackgroundPageScaffold(
      actions: [
        IconButton(
          tooltip: context.l10n.flowRules,
          icon: const Icon(Icons.info_outline_rounded, size: 20),
          onPressed: _showRulesDialog,
        ),
        IconButton(
          tooltip: context.l10n.flowSettings,
          icon: const Icon(Icons.settings_outlined, size: 20),
          onPressed: _showSettingsDialog,
        ),
        IconButton(
          tooltip: context.l10n.flowNewQuestion,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          onPressed: _startNewGame,
        ),
      ],
      title: context.l10n.featureAliasSongQuiz,
      resizeToAvoidBottomInset: false,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showSearchResults = false;
          });
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 边距
            double padding = screenWidth * 0.04;

            return Column(
              children: [
                // 主要内容
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(padding, 8, padding, padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _isGameStarted
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                    // 本局状态与每日统计共用布局。
                                    GuessGameStatusPanel(
                                      roundLabel: context.l10n.flowGuessesLeft,
                                      roundValue: _maxGuesses > 0
                                          ? (_maxGuesses - _guessCount)
                                              .clamp(0, _maxGuesses)
                                              .toString()
                                          : '∞',
                                      roundTotal:
                                          _maxGuesses > 0 ? '$_maxGuesses' : '∞',
                                      answer: _targetSong?.basicInfo.title,
                                      stats: _stats,
                                      onResetStats: _resetAndRefreshStats,
                                      timeLimit: _timeLimit,
                                      remainingTime: _remainingTime,
                                      isGameOver: _isGameOver,
                                      isWon: _isWon,
                                    ),
                                    const SizedBox(height: 20),

                                    // 别名展示（抽不到曲时这块换成原因说明）
                                    Center(
                                      child: _buildAliasDisplay(),
                                    ),

                                    const SizedBox(height: 20),

                                    // 游戏结果显示（抽不到曲时没有答案卡片）
                                    if (_isGameOver && _targetSong != null)
                                      GestureDetector(
                                        onTap: () {
                                          if (_targetSong != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    SongInfoPage(
                                                  songId: _targetSong!.id,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(top: 20),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppColors.guessAnswerCardBg(
                                                brightness),
                                            borderRadius:
                                                BorderRadius.circular(AppDesignTokens.radiusSmall),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _isWon ? context.l10n.flowYouGotIt : context.l10n.flowThisGameSAnswer,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: _isWon
                                                      ? AppColors.successGreen(
                                                          brightness)
                                                      : AppColors.linkBlue(
                                                          brightness),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              if (_targetSong != null)
                                                Row(
                                                  children: [
                                                    // 曲绘
                                                    Container(
                                                      width: 60,
                                                      height: 60,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                        child: GuessCoverImage(
                                                            songId:
                                                                _targetSong!.id,
                                                            size: 60),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          // 第一行：类型 曲名
                                                          Row(
                                                            children: [
                                                              Text(
                                                                _targetSong!.type ==
                                                                        'SD'
                                                                    ? 'ST'
                                                                    : _targetSong!
                                                                        .type,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: _targetSong!
                                                                              .type ==
                                                                          'SD'
                                                                      ? Colors
                                                                          .blue
                                                                      : Colors
                                                                          .orange,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  width: 8),
                                                              Expanded(
                                                                child: Text(
                                                                  _targetSong!
                                                                      .basicInfo
                                                                      .title,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize: 14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          // 第二行：曲师 | 流派
                                                          Text(
                                                            '${_targetSong!.basicInfo.artist} | ${_targetSong!.basicInfo.genre}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          // 第三行：masterDs | remasterDs | version
                                                          Text(
                                                            '${_targetSong!.ds.length > 3 ? _targetSong!.ds[3].toString() : '-'} | ${_targetSong!.ds.length > 4 ? _targetSong!.ds[4].toString() : '-'} | ${StringUtil.formatVersion2WithFlag(_targetSong!.basicInfo.from, _targetSong!.isExtra)}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    const SizedBox(height: 20),

                                    // 猜测历史
                                    if (_guessHistory.isNotEmpty)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          GuessHistoryHeader(
                            ascending: _isAscending,
                            onToggleSort: () =>
                                setState(() => _isAscending = !_isAscending),
                          ),
                                          const SizedBox(height: 12),
                                          ...(() {
                                            // 根据排序状态处理猜测历史
                                            List<MapEntry<int, GuessSong>>
                                                entries = _guessHistory
                                                    .asMap()
                                                    .entries
                                                    .toList();
                                            if (!_isAscending) {
                                              // 逆序排序
                                              entries =
                                                  entries.reversed.toList();
                                            }
                                            return entries.map((entry) {
                                              int index = entry.key;
                                              GuessSong guessSong = entry.value;
                                              return _buildGuessHistoryItem(
                                                  guessSong, index, null);
                                            }).toList();
                                          })(),
                                        ],
                                      ),
                                  ])
                            : GuessChartLoadingView(
                                message: _loadFailureMessage,
                                onOpenSettings: _openSettingsAndRestart,
                                // 只有「曲库真的没数据」才给重拉按钮：
                                // 筛选太严时该做的是去设置里放宽条件。
                                onRetry: _loadFailureMessage ==
                                        GuessChartLoadingView
                                            .emptyLibraryMessage
                                    ? _retryStartGame
                                    : null,
                              ),
                      ],
                    ),
                  ),
                ),
                if (_isGameStarted)
                  GuessInputBar(
                    controller: _searchController,
                    onChanged: _handleSearchInput,
                    hintText: context.l10n.flowSearchTitleAliasIDAndMore,
                    isGameOver: _isGameOver,
                    onSurrender: () async {
                                                // 投降时取消倒计时
                                                _countdownTimer?.cancel();
                                                setState(() {
                                                  _isGameOver = true;
                                                  _isWon = false;
                                                });
                                                // 记录失败
                                                await _recordGameResult(false);
                                              },
                    onNewGame: _startNewGame,
                    showResults: _showSearchResults,
                    searching: _isSearching,
                    resultCount: _searchResults.length,
                    resultBuilder: (context, index) =>
                        _buildSearchResultItem(_searchResults[index]),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
