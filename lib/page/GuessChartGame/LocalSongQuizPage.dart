import 'dart:math';

import 'package:flutter/material.dart';

import '../../entity/DivingFish/Song.dart';
import '../../l10n/LocalizationsExtension.dart';
import '../../service/SongSearchService.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppTheme.dart';
import '../../utils/CoverUtil.dart';
import '../../widgets/AnimatedChoiceBar.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/BackgroundPageScaffold.dart';

enum _Quiz { difficulty, questions }

/// 本地曲库离线挑战：极限二选一与规则版 20 问。
class LocalSongQuizPage extends StatefulWidget {
  const LocalSongQuizPage({super.key});

  @override
  State<LocalSongQuizPage> createState() => _LocalSongQuizPageState();
}

class _LocalSongQuizPageState extends State<LocalSongQuizPage> {
  final _random = Random();
  final _answers = <int, bool>{};
  List<Song>? _library;
  List<Song> _choices = const [];
  Song? _answer;
  Song? _picked;
  _Quiz _quiz = _Quiz.difficulty;
  int _wins = 0;
  int _rounds = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  double _difficulty(Song song) => song.ds.where((v) => v > 0).fold(0.0, max);

  Future<void> _load() async {
    final songs = await SongSearchService.loadAllSongs();
    if (!mounted) return;
    setState(() {
      final unique = <String, Song>{};
      for (final song in songs ?? const <Song>[]) {
        if (_difficulty(song) > 0 && song.title.isNotEmpty && !song.isExtra) {
          unique.putIfAbsent(song.title, () => song);
        }
      }
      _library = unique.values.toList();
      _newRound();
    });
  }

  void _newRound() {
    final pool = [...?_library]..shuffle(_random);
    _answers.clear();
    _picked = null;
    _answer = null;
    _choices = const [];
    if (pool.length < 2) return;
    final first = pool.first;
    if (_quiz == _Quiz.questions) {
      _answer = first;
      _choices = pool.take(24).toList()
        ..sort((a, b) => a.title.compareTo(b.title));
      return;
    }
    final second = pool
        .skip(1)
        .where((song) => _difficulty(song) != _difficulty(first))
        .firstOrNull;
    if (second == null) return;
    _choices = [first, second];
    _answer = _difficulty(first) > _difficulty(second) ? first : second;
  }

  void _pick(Song song) => setState(() {
        _picked = song;
        _rounds++;
        if (song == _answer) _wins++;
      });

  List<(String, bool Function(Song))> get _questions => [
        for (final bpm in [100, 120, 140, 160, 180, 200, 220, 240])
          ('BPM ≥ $bpm', (song) => song.basicInfo.bpm >= bpm),
        for (final ds in [10, 11, 12, 13, 14, 14.5, 15])
          (
            '${context.l10n.flowConstant} ≥ $ds',
            (song) => _difficulty(song) >= ds
          ),
        ('DX', (song) => song.type.toUpperCase() == 'DX'),
        for (final length in [5, 10, 15, 20])
          (
            '${context.l10n.awmcQuizTitleLength} ≥ $length',
            (song) => song.title.runes.length >= length
          ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final answer = _answer;
    final questions = _questions;
    final shown = _choices
        .where((song) =>
            _answers.entries.every((e) => questions[e.key].$2(song) == e.value))
        .toList();

    return BackgroundPageScaffold(
      title: l10n.awmcLocalQuizzes,
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 24),
        children: [
          AnimatedChoiceBar<_Quiz>(
            values: _Quiz.values,
            value: _quiz,
            label: (mode) => mode == _Quiz.difficulty
                ? l10n.awmcQuizEither
                : l10n.awmcQuizTwenty,
            onChanged: (mode) => setState(() {
              _quiz = mode;
              _newRound();
            }),
          ),
          const SizedBox(height: AppDesignTokens.cardGap),
          if (_library == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (answer == null)
            AppCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.library_music_outlined,
                        size: 32, color: scheme.outline),
                    const SizedBox(height: 8),
                    Text(
                      l10n.flowNoSongData,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _quiz == _Quiz.difficulty
                              ? l10n.awmcQuizHarder
                              : l10n.awmcQuizDeduction,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (_rounds > 0) ...[
                        const SizedBox(width: 8),
                        AppBadge(
                          text: '$_wins / $_rounds',
                          background: scheme.primary.withValues(alpha: 0.12),
                          foreground: scheme.primary,
                        ),
                      ],
                    ],
                  ),
                  if (_quiz == _Quiz.questions) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.awmcQuizQuestionsUsed} ${_answers.length} / 20',
                      style: AppTheme.number(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppDesignTokens.cardGap),
            if (_quiz == _Quiz.questions && _picked == null) ...[
              AppCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (index, question) in questions.indexed)
                      _buildQuestionChip(context, index, question.$1,
                          question.$2, answer, brightness),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.cardGap),
            ],
            if (_quiz == _Quiz.difficulty)
              for (final (index, song) in shown.indexed) ...[
                if (index > 0) const SizedBox(height: 10),
                _buildDifficultyChoiceCard(context, song, answer, brightness),
              ]
            else
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSectionHeader(
                      title: l10n.awmcQuizTwenty,
                      padding: const EdgeInsets.only(bottom: 10),
                      trailing: AppBadge(
                        text: '${shown.length}',
                        background: AppSurfaces.inset(context),
                        foreground: scheme.onSurfaceVariant,
                      ),
                    ),
                    for (final (index, song) in shown.indexed) ...[
                      if (index > 0) const SizedBox(height: 8),
                      _buildQuestionCandidateRow(
                          context, song, answer, brightness),
                    ],
                  ],
                ),
              ),
            if (_picked != null) ...[
              const SizedBox(height: AppDesignTokens.cardGap),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${l10n.awmcQuizAnswer} · ${answer.title}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppDesignTokens.radiusMedium),
                          ),
                        ),
                        onPressed: () => setState(_newRound),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(l10n.flowNextRound),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionChip(
    BuildContext context,
    int index,
    String label,
    bool Function(Song) predicate,
    Song answer,
    Brightness brightness,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final hit = _answers[index];
    if (hit != null) {
      final color = hit
          ? AppColors.successGreen(brightness)
          : AppColors.errorRed(brightness);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          '$label ${hit ? '✓' : '×'}',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
    }
    return Material(
      color: AppSurfaces.inset(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      ),
      child: InkWell(
        onTap: () => setState(() => _answers[index] = predicate(answer)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyChoiceCard(
    BuildContext context,
    Song song,
    Song answer,
    Brightness brightness,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final revealed = _picked != null;
    final isAnswer = song == answer;
    final isPickedWrong = song == _picked && !isAnswer;
    final Color? statusColor = !revealed
        ? null
        : isAnswer
            ? AppColors.successGreen(brightness)
            : isPickedWrong
                ? AppColors.errorRed(brightness)
                : null;

    return Container(
      foregroundDecoration: statusColor == null
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
              border: Border.all(
                  color: statusColor.withValues(alpha: 0.65), width: 1.5),
            ),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: revealed ? null : () => _pick(song),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              child: CoverUtil.buildCoverWidgetWithContext(context, song.id, 56),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      SongTypeBadge(songId: song.id, type: song.type),
                      if (song.basicInfo.artist.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            song.basicInfo.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (revealed) ...[
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_difficulty(song)}',
                    style: AppTheme.number(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: statusColor ?? scheme.onSurface,
                    ),
                  ),
                  if (statusColor != null) ...[
                    const SizedBox(height: 2),
                    Icon(
                      isAnswer
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 18,
                      color: statusColor,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCandidateRow(
    BuildContext context,
    Song song,
    Song answer,
    Brightness brightness,
  ) {
    final revealed = _picked != null;
    final isAnswer = song == answer;
    final isPickedWrong = song == _picked && !isAnswer;
    return Material(
      color: AppSurfaces.inset(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      ),
      child: InkWell(
        onTap: revealed ? null : () => _pick(song),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    CoverUtil.buildCoverWidgetWithContext(context, song.id, 36),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  song.title,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
              if (revealed && (isAnswer || isPickedWrong)) ...[
                const SizedBox(width: 8),
                Icon(
                  isAnswer ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 18,
                  color: isAnswer
                      ? AppColors.successGreen(brightness)
                      : AppColors.errorRed(brightness),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
