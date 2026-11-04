import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_flutter_app/constant/CacheKeyConstant.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/entity/KaleidXScope/KaleidXScopeGate.dart';
import 'package:my_first_flutter_app/manager/DivingFish/MaimaiMusicDataManager.dart';
import 'package:my_first_flutter_app/page/Collection/CollectionInfoPage.dart';
import 'package:my_first_flutter_app/page/SongInfoPage.dart';
import 'package:my_first_flutter_app/service/KaleidXScope/KaleidXScopeGateService.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/widgets/AppSwitch.dart';
import 'package:my_first_flutter_app/widgets/AppUi.dart';
import 'package:my_first_flutter_app/widgets/BackgroundPageScaffold.dart';
import 'package:my_first_flutter_app/widgets/KaleidXScopeSourceNotice.dart';
import 'package:my_first_flutter_app/widgets/LxnsAssetImage.dart';
import 'package:my_first_flutter_app/widgets/ProgressUi.dart';
import 'package:my_first_flutter_app/widgets/SmoothLinearProgressIndicator.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/KaleidDateUtil.dart';
import '../../widgets/ImageLoadingIndicator.dart';

/// 各门的固定配置：接口缺字段时的兜底文案、门图、能否标记曲目。
class _GateConfig {
  final String title;
  final String? asset;
  final String? markKey;
  final String? doorName;
  final String? prerequisite;
  final bool prerequisiteIsArea;
  final String? keyRequirement;
  final String? guideNote;
  final String? track1;
  final String? track2;
  final String? track3;
  final int? frameCollectionId;

  const _GateConfig({
    required this.title,
    this.asset,
    this.markKey,
    this.doorName,
    this.prerequisite,
    this.prerequisiteIsArea = false,
    this.keyRequirement,
    this.guideNote,
    this.track1,
    this.track2,
    this.track3,
    this.frameCollectionId,
  });
}

const _commonTrack1 = '所有区域歌曲';
const _commonTrack2 = '所有区域内的完美挑战曲';
const _commonTrack3 = '固定，即为隐藏歌曲';

const Map<String, _GateConfig> _gateConfigs = {
  'blue': _GateConfig(
    title: '蓝色之门详情',
    asset: 'assets/kaleidxscope/blue.webp',
    markKey: CacheKeyConstant.kaleidXBlueGateMarkedSongs,
    doorName: '青门（蓝色之门）门扉',
    prerequisite: '天空街区域6',
    prerequisiteIsArea: true,
    track1: _commonTrack1,
    track2: _commonTrack2,
    track3: _commonTrack3,
  ),
  'white': _GateConfig(
    title: '白门详情',
    asset: 'assets/kaleidxscope/white.webp',
    doorName: '白门门扉',
    prerequisite: '天界区域8',
    prerequisiteIsArea: true,
    track1: _commonTrack1,
    track2: _commonTrack2,
    track3: _commonTrack3,
    frameCollectionId: 459504,
  ),
  'purple': _GateConfig(
    title: '紫色之门详情',
    asset: 'assets/kaleidxscope/purple.webp',
    doorName: '紫门门扉',
    prerequisite: '紫蔷薇区域10',
    prerequisiteIsArea: true,
    track1: _commonTrack1,
    track2: _commonTrack2,
    track3: _commonTrack3,
  ),
  'black': _GateConfig(
    title: '黑色之门详情',
    asset: 'assets/kaleidxscope/black.webp',
    markKey: CacheKeyConstant.kaleidXBlackGateMarkedSongs,
    doorName: '黑门门扉',
    prerequisite: '大都会区域9',
    prerequisiteIsArea: true,
    keyRequirement: '完成下方曲目池内的11首歌曲（全部游玩）',
    guideNote: '可：跳过（Track Skip）/不可：段位认定和宴会场',
    track1: _commonTrack1,
    track2: _commonTrack2,
    track3: _commonTrack3,
  ),
  'yellow': _GateConfig(
    title: '黄色之门详情',
    asset: 'assets/kaleidxscope/yellow.webp',
    doorName: '黄门门扉',
    prerequisite: '七彩区域（なないろちほー）',
    keyRequirement: '在门更新之后，使用随机选曲，随出一次以下曲目池中的任意一首并游玩',
    guideNote: '（不限难度，不需要一次随出可以返回重试，可以使用收藏分类）',
    track1: '启程区域随机选曲',
    track2: '启程区域随机完美挑战曲、MAXRAGE和UniTas',
    track3: 'Åntinomiε',
  ),
  'red': _GateConfig(
    title: '红色之门详情',
    asset: 'assets/kaleidxscope/red.webp',
    markKey: CacheKeyConstant.kaleidXRedGateMarkedSongs,
    doorName: '赤门（红色之门）门扉',
  ),
  'prism': _GateConfig(title: '棱镜塔详情', asset: 'assets/kaleidxscope/prism.png'),
  'error': _GateConfig(title: '乱码之门详情'),
  'hope': _GateConfig(title: '希望之门详情', asset: 'assets/kaleidxscope/hope.png'),
  'final': _GateConfig(title: '最终相详情', asset: 'assets/kaleidxscope/final.png'),
};

/// 所有门共用的详情页，门之间的差异都在 [_gateConfigs] 和门接口的数据里。
class KaleidXScopeGatePage extends StatefulWidget {
  final String color;
  final String title;

  const KaleidXScopeGatePage({
    super.key,
    required this.color,
    required this.title,
  });

  @override
  State<KaleidXScopeGatePage> createState() => _KaleidXScopeGatePageState();
}

class _KaleidXScopeGatePageState extends State<KaleidXScopeGatePage> {
  KaleidXScopeGate? _gateData;
  Map<int, Song> _songMap = {};
  bool _isLoading = true;
  String? _error;

  int _tab = 0; // 0 攻略，1 曲目
  int _songSource = 0; // 曲目标签里当前看哪一组
  bool _isMarkMode = false;
  Set<String> _markedIds = {};

  _GateConfig get _config =>
      _gateConfigs[widget.color] ?? _GateConfig(title: widget.title);

  Color get _accent =>
      AppColors.kaleidGateAccent(widget.color, Theme.of(context).brightness) ??
      Theme.of(context).colorScheme.primary;

  @override
  void initState() {
    super.initState();
    _load();
    _loadMarkedSongs();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final gate = await KaleidXScopeGateService().fetchGate(widget.color);
      final catalog = await MaimaiMusicDataManager().getCachedSongs();
      if (!mounted) return;
      setState(() {
        _gateData = gate;
        _songMap = {
          for (final song in catalog ?? <Song>[])
            if (int.tryParse(song.id) != null) int.parse(song.id): song,
        };
      });
    } catch (e) {
      if (mounted) setState(() => _error = '攻略加载失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMarkedSongs() async {
    final key = _config.markKey;
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      if (cached != null && cached.isNotEmpty && mounted) {
        setState(() => _markedIds = cached.split(',').toSet());
      }
    } catch (e) {
      debugPrint('加载标记歌曲缓存失败: $e');
    }
  }

  Future<void> _saveMarkedSongs() async {
    final key = _config.markKey;
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, _markedIds.join(','));
    } catch (e) {
      debugPrint('保存标记歌曲缓存失败: $e');
    }
  }

  List<int> _trackIds(String key) => _gateData?.songs[key] ?? const <int>[];

  /// 曲目池：接口有 gate 列表就用它，新门没有时取三个 Track 的合集。
  List<int> get _poolIds {
    final gateIds = _trackIds('gate');
    if (gateIds.isNotEmpty) return gateIds;
    return {
      ..._trackIds('track1'),
      ..._trackIds('track2'),
      ..._trackIds('track3'),
    }.toList();
  }

  List<(String, List<int>)> get _songSources => [
        if (_poolIds.isNotEmpty) ('曲目池', _poolIds),
        if (_trackIds('track1').isNotEmpty) ('Track 1', _trackIds('track1')),
        if (_trackIds('track2').isNotEmpty) ('Track 2', _trackIds('track2')),
        if (_trackIds('track3').isNotEmpty) ('Track 3', _trackIds('track3')),
      ];

  void _openSong(Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongInfoPage(songId: song.id, initialLevelIndex: 3),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'dx':
        return 'DX';
      case 'standard':
      case 'sd':
        return 'ST';
      default:
        return type;
    }
  }

  ({Color background, Color foreground}) _difficultyColors(String label) {
    final brightness = Theme.of(context).brightness;
    final index = ChartDifficulty.indexOf(label);
    if (index == null || !ChartDifficulty.isStandard(index)) {
      return (
        background: _accent.withValues(alpha: 0.14),
        foreground: _accent,
      );
    }
    return (
      background:
          AppColors.difficultyBackgroundByIndex(index, brightness: brightness),
      foreground:
          AppColors.difficultyForegroundByIndex(index, brightness: brightness),
    );
  }

  Widget _boxSliver(Widget child) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppDesignTokens.gutter),
        sliver: SliverToBoxAdapter(child: child),
      );

  Widget _difficultyBadge(String label) {
    final colors = _difficultyColors(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: AppTheme.number(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1.1,
          color: colors.foreground,
        ),
      ),
    );
  }

  // ===== 头图 =====

  Widget _buildHero() {
    final gate = _gateData!;
    final scheme = Theme.of(context).colorScheme;
    // 有的门同时进行两个挑战（完美挑战和门本身），各自有独立的 LIFE
    final current = [
      for (final challenge in gate.challenges)
        if (KaleidDateUtil.currentPhase([challenge]) case final phase?)
          (name: challenge.name, phase: phase),
    ];
    final asset = _config.asset;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: _accent.withValues(alpha: 0.1),
            child: asset == null
                ? SizedBox(
                    height: 120,
                    child: Icon(Icons.door_back_door_outlined,
                        size: 72, color: _accent),
                  )
                : Image.asset(asset, height: 170, fit: BoxFit.contain),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gate.doorName ??
                      gate.displayName ??
                      _config.doorName ??
                      widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppSurfaces.inset(context),
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusSmall),
                  ),
                  child: current.isEmpty
                      ? Text(
                          '暂无进行中的挑战，可以看看下方的时间安排',
                          style: TextStyle(
                              fontSize: 13, color: scheme.onSurfaceVariant),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final (index, item) in current.indexed) ...[
                              if (index > 0)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(
                                      height: 1,
                                      color: scheme.outlineVariant),
                                ),
                              _buildCurrentPhase(
                                item.phase,
                                challengeName:
                                    current.length > 1 ? item.name : null,
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 只有最终相的血量分一阶段、二阶段。其它门接口里的 target 不是血量，不显示。
  bool get _hasTwoLifeStages => widget.color == 'final';

  Widget _buildCurrentPhase(ChallengePhase phase, {String? challengeName}) {
    final scheme = Theme.of(context).colorScheme;
    final twoStages = _hasTwoLifeStages && phase.target != null;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                challengeName ?? '当前阶段',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              _difficultyBadge(phase.difficulty),
              const SizedBox(height: 4),
              Text(
                KaleidDateUtil.range(phase.startDate, phase.endDate),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              twoStages ? 'LIFE 一阶段 / 二阶段' : 'LIFE',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            Text(
              twoStages
                  ? '${phase.lifeTarget} / ${phase.target}'
                  : '${phase.lifeTarget}',
              style: AppTheme.number(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: _accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===== 攻略 =====

  Widget _buildStep(int number, String title, List<Widget> children,
      {bool last = false}) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: AppTheme.number(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _accent,
                  ),
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: scheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2, bottom: last ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...children,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bodyText(String text) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );

  Widget _buildFrame(KaleidXScopeGate gate) {
    final id = gate.frameCollectionId ?? _config.frameCollectionId;
    final url = gate.frameImageUrl ??
        (id == null ? null : 'https://assets2.lxns.net/maimai/frame/$id.png');
    if (url == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: id == null
            ? null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CollectionInfoPage(
                      collectionId: id,
                      collectionType: gate.frameCollectionType ?? 'frames',
                    ),
                  ),
                ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
          child: CachedNetworkImage(
            cacheManager: lxnsAssetCacheManager,
            imageUrl: url,
            height: 100,
            fit: BoxFit.contain,
            placeholder: (_, __) => const ImageLoadingIndicator(
                background: Colors.transparent),
            errorWidget: (_, __, ___) =>
                const Center(child: Icon(Icons.image_not_supported_outlined)),
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockCard() {
    final gate = _gateData!;
    final config = _config;
    final prerequisite = gate.prerequisite ?? config.prerequisite;
    final key = gate.keyRequirement ?? config.keyRequirement;
    final note = gate.guideNote ?? config.guideNote;
    final track1 = gate.track1Desc ?? config.track1;
    final track2 = gate.track2Desc ?? config.track2;
    final track3 = gate.track3Desc ?? config.track3;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStep(1, '门扉条件', [
            _bodyText(prerequisite == null
                ? '（未设置）'
                : '${config.prerequisiteIsArea ? '完成' : ''}$prerequisite'),
          ]),
          _buildStep(2, '钥匙（挑战所需的物品）', [
            if (key?.isNotEmpty == true) _bodyText(key!),
            _buildFrame(gate),
            if (note?.isNotEmpty == true) _bodyText(note!),
          ]),
          _buildStep(
            3,
            'KALEIDXSCOPE 模式',
            [
              _bodyText('第一首：${track1 ?? '（未设置）'}'),
              if (track2 != null) _bodyText('第二首：$track2'),
              if (track3 != null) _bodyText('第三首：$track3'),
            ],
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialSongs() {
    final specials = _gateData!.specialSongs;
    if (specials.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppDesignTokens.cardGap),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, special) in specials.indexed)
              _SongRow(
                songId: special.songId,
                song: _songMap[special.songId],
                caption: switch (special.role) {
                  'perfect' => '完美挑战曲',
                  'reward' => '通关解锁歌曲',
                  _ => '隐藏歌曲',
                },
                captionColor: _accent,
                typeLabel: _typeLabel,
                showDivider: index > 0,
                dividerColor: scheme.outlineVariant,
                onTap: _songMap[special.songId] == null
                    ? null
                    : () => _openSong(_songMap[special.songId]!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(KaleidXScopeChallenge challenge) {
    final scheme = Theme.of(context).colorScheme;
    final current = KaleidDateUtil.currentPhase([challenge]);
    return Padding(
      padding: const EdgeInsets.only(top: AppDesignTokens.cardGap),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              challenge.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            _buildChallengeBar(challenge.phases),
            const SizedBox(height: 8),
            for (final phase in challenge.phases)
              _buildChallengePhase(
                phase,
                isCurrent: identical(phase, current),
                showFinalPhaseDetails: _hasTwoLifeStages,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengePhase(
    ChallengePhase phase, {
    required bool isCurrent,
    required bool showFinalPhaseDetails,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final dateStyle = TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant);
    final lifeStyle = AppTheme.number(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    );
    // 接口格式是 `P -1|Gr -5|Gd -10|M -20`，显示成 `小P-1 GREAT-5 GOOD-10 MISS-20`。
    const penaltyNames = {'P': '小P', 'Gr': 'GREAT', 'Gd': 'GOOD', 'M': 'MISS'};
    final penalties = (phase.penalties ?? '')
        .split('|')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map((item) {
      final parts = item.split(RegExp(r'\s+'));
      return '${penaltyNames[parts.first] ?? parts.first}${parts.skip(1).join()}';
    }).toList();
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: isCurrent ? _accent.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  KaleidDateUtil.range(phase.startDate, phase.endDate),
                  style: dateStyle,
                ),
              ),
              if (isCurrent) ...[
                Text(
                  '进行中',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _accent,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              _difficultyBadge(phase.difficulty),
              if (!showFinalPhaseDetails) ...[
                const SizedBox(width: 8),
                Text('LIFE ${phase.lifeTarget}', style: lifeStyle),
              ],
            ],
          ),
          if (showFinalPhaseDetails) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                Text('一阶段 ${phase.lifeTarget}', style: lifeStyle),
                Text('二阶段 ${phase.target ?? '-'}', style: lifeStyle),
              ],
            ),
            if (penalties.isNotEmpty) ...[
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < penalties.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Text(penalties[i], maxLines: 1, style: dateStyle),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// 难度时间条：阶段很多时折成多行，每个难度名都完整显示在一行内。
  ///
  /// 不能按阶段数等分：最终相有 9 段，`Re:MASTER` 在窄屏上会被挤到换行。
  /// 按最宽的标签决定每格的宽度下限，放不下的格子折到下一行；
  /// 极端窄屏或大字号下用 `FittedBox` 等比缩小，不换行也不省略。
  Widget _buildChallengeBar(List<ChallengePhase> phases) {
    if (phases.isEmpty) return const SizedBox.shrink();
    const fontSize = 11.0;
    const cellHeight = 24.0;
    const cellPadding = 4.0;
    const separator = 2.0; // 相邻格之间露出的细缝

    // 量宽度必须带 textScaler，否则系统字体调大后会算得下、画出来却换行。
    final scaler = MediaQuery.textScalerOf(context);
    final maxLabelWidth = phases.map((phase) {
      final painter = TextPainter(
        text: TextSpan(
          text: phase.difficulty,
          style: const TextStyle(
              fontSize: fontSize, fontWeight: FontWeight.bold),
        ),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }).reduce((a, b) => a > b ? a : b);
    final minCellWidth = maxLabelWidth + cellPadding * 2;

    return LayoutBuilder(builder: (context, constraints) {
      final available = constraints.maxWidth;
      final maxPerRow =
          available <= 0 ? 1 : (available / minCellWidth).floor().clamp(1, 32);

      // 贪心装箱：一行放不下就换行，行内等分。
      final rows = <List<ChallengePhase>>[];
      var current = <ChallengePhase>[];
      var currentWidth = 0.0;
      for (final phase in phases) {
        final added = current.isEmpty ? minCellWidth : minCellWidth + separator;
        if (current.isNotEmpty &&
            (current.length >= maxPerRow || currentWidth + added > available)) {
          rows.add(current);
          current = <ChallengePhase>[];
          currentWidth = 0;
        }
        currentWidth +=
            current.isEmpty ? minCellWidth : minCellWidth + separator;
        current.add(phase);
      }
      if (current.isNotEmpty) rows.add(current);

      return Column(
        children: [
          for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
            if (rowIndex > 0) const SizedBox(height: separator),
            ClipRRect(
              borderRadius: BorderRadius.circular(cellHeight / 2),
              child: SizedBox(
                height: cellHeight,
                child: Row(children: [
                  for (var i = 0; i < rows[rowIndex].length; i++) ...[
                    if (i > 0) const SizedBox(width: separator),
                    Expanded(
                      child: Container(
                        color: _difficultyColors(rows[rowIndex][i].difficulty)
                            .background,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            rows[rowIndex][i].difficulty,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: fontSize,
                              height: 1,
                              fontWeight: FontWeight.bold,
                              color: _difficultyColors(
                                      rows[rowIndex][i].difficulty)
                                  .foreground,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ],
      );
    });
  }

  // ===== 曲目 =====

  Widget _buildMarkPanel(List<int> ids) {
    final scheme = Theme.of(context).colorScheme;
    final marked = ids.where((id) => _markedIds.contains('$id')).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignTokens.cardGap),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '已标记 $marked / ${ids.length}',
                        style: AppTheme.number(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        _isMarkMode ? '点击歌曲可切换完成状态' : '开启标记后点歌曲记录完成情况',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: '标记模式',
                  child: AppSwitch(
                    value: _isMarkMode,
                    onChanged: (value) => setState(() => _isMarkMode = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SmoothLinearProgressIndicator(
              value: ids.isEmpty ? 0 : marked / ids.length,
              minHeight: 6,
              color: _accent,
              backgroundColor: AppSurfaces.inset(context),
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSongSlivers() {
    final sources = _songSources;
    if (sources.isEmpty) {
      return [
        _boxSliver(Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            '暂无歌曲数据',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        )),
      ];
    }
    final index = _songSource.clamp(0, sources.length - 1).toInt();
    final (title, ids) = sources[index];
    // 只有曲目池能标记：钥匙条件针对的是曲目池。
    final markable = _config.markKey != null && title == '曲目池';
    final scheme = Theme.of(context).colorScheme;
    return [
      _boxSliver(Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sources.length > 1) ...[
            PillTabs(
              items: [
                for (final (label, _) in sources) SegmentedTabItem(label),
              ],
              selectedIndex: index,
              onChanged: (value) => setState(() => _songSource = value),
            ),
            const SizedBox(height: AppDesignTokens.cardGap),
          ],
          if (markable) _buildMarkPanel(ids),
        ],
      )),
      ProgressSongSliver(
        groups: [
          ProgressSongGroup(
            title: title,
            items: [
              for (final id in ids) {'id': id},
            ],
          ),
        ],
        showListMode: true,
        coverBuilder: (_) => const SizedBox.shrink(),
        rowBuilder: (item, showDivider) {
          final id = item['id'] as int;
          final song = _songMap[id];
          final marked = markable && _markedIds.contains('$id');
          return _SongRow(
            songId: id,
            song: song,
            typeLabel: _typeLabel,
            showDivider: showDivider,
            dividerColor: scheme.outlineVariant,
            trailing: markable && (_isMarkMode || marked)
                ? Icon(
                    marked
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 22,
                    color: marked
                        ? AppColors.successForeground(
                            Theme.of(context).brightness)
                        : scheme.outline,
                  )
                : null,
            onTap: () {
              if (markable && _isMarkMode) {
                setState(() {
                  if (!_markedIds.remove('$id')) _markedIds.add('$id');
                });
                _saveMarkedSongs();
              } else if (song != null) {
                _openSong(song);
              }
            },
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget body;
    if (_isLoading) {
      body = const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            AppDesignTokens.gutter, 8, AppDesignTokens.gutter, 16),
        child: ProgressListSkeleton(),
      );
    } else if (_error != null || _gateData == null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 40, color: scheme.outline),
            const SizedBox(height: 10),
            Text(_error ?? '攻略加载失败，请稍后重试',
                style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            FilledButton.tonal(onPressed: _load, child: const Text('重试')),
          ],
        ),
      );
    } else {
      final gate = _gateData!;
      body = CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 8,
                AppDesignTokens.gutter, AppDesignTokens.cardGap),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EntranceAnimation(child: _buildHero()),
                  const SizedBox(height: AppDesignTokens.cardGap),
                  SegmentedTabs(
                    items: const [
                      SegmentedTabItem('攻略'),
                      SegmentedTabItem('曲目'),
                    ],
                    selectedIndex: _tab,
                    onChanged: (value) => setState(() => _tab = value),
                  ),
                ],
              ),
            ),
          ),
          ProgressSliverFade(
            key: ValueKey(_tab),
            sliver: SliverMainAxisGroup(
              slivers: _tab == 0
                  ? [
                      _boxSliver(Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildUnlockCard(),
                          _buildSpecialSongs(),
                          for (final challenge in gate.challenges)
                            _buildChallengeCard(challenge),
                        ],
                      )),
                    ]
                  : _buildSongSlivers(),
            ),
          ),
          const SliverToBoxAdapter(
              child: SizedBox(height: AppDesignTokens.gutter)),
        ],
      );
    }
    return BackgroundPageScaffold(
      title: _config.title,
      bottom: const KaleidXScopeSourceNotice(),
      contentPadding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: body,
    );
  }
}

/// 歌曲一行：曲绘、歌名、类型和版本、全部难度的定数。曲库里没有这首时显示 ID。
class _SongRow extends StatelessWidget {
  final int songId;
  final Song? song;
  final String? caption;
  final Color? captionColor;
  final String Function(String) typeLabel;
  final bool showDivider;
  final Color dividerColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SongRow({
    required this.songId,
    required this.song,
    required this.typeLabel,
    required this.showDivider,
    required this.dividerColor,
    this.caption,
    this.captionColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final song = this.song;
    final metaStyle = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: showDivider
            ? BoxDecoration(
                border: Border(top: BorderSide(color: dividerColor)))
            : null,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              child: SizedBox(
                width: 46,
                height: 46,
                child: CoverUtil.buildCoverWidgetWithContext(
                    context, '$songId', 46),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (caption != null)
                    Text(
                      caption!,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: captionColor,
                      ),
                    ),
                  Text(
                    song?.title ?? '歌曲 ID $songId',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song == null
                        ? '刷新曲库后显示歌曲信息'
                        : '${typeLabel(song.type)} | ${StringUtil.formatVersion2WithFlag(song.basicInfo.from, song.isExtra)}',
                    style: metaStyle,
                  ),
                  if (song != null) ...[
                    const SizedBox(height: 4),
                    ChartConstantBadges(
                      constants: song.ds,
                      isUtage: '$songId'.length == 6,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}
