import 'dart:math';

import 'package:flutter/material.dart';

import '../../entity/DivingFish/Song.dart';
import '../../l10n/LocalizationsExtension.dart';
import '../../service/SongSearchService.dart';
import '../../widgets/AnimatedChoiceBar.dart';
import '../../widgets/BackgroundPageScaffold.dart';

enum _Quiz { difficulty, questions }

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
    final answer = _answer;
    final questions = _questions;
    final shown = _choices.where((song) =>
        _answers.entries.every((e) => questions[e.key].$2(song) == e.value));
    return BackgroundPageScaffold(
      title: l10n.awmcLocalQuizzes,
      child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                    })),
            const SizedBox(height: 16),
            if (_library == null)
              const Center(child: CircularProgressIndicator())
            else if (answer == null)
              Text(l10n.flowNoSongData)
            else ...[
              Text(_quiz == _Quiz.difficulty
                  ? l10n.awmcQuizHarder
                  : l10n.awmcQuizDeduction),
              if (_rounds > 0) Text('$_wins / $_rounds'),
              if (_quiz == _Quiz.questions && _picked == null) ...[
                const SizedBox(height: 8),
                Text('${l10n.awmcQuizQuestionsUsed} ${_answers.length} / 20'),
                Wrap(spacing: 8, children: [
                  for (final (index, question) in questions.indexed)
                    TextButton(
                      onPressed: _answers.containsKey(index)
                          ? null
                          : () => setState(
                              () => _answers[index] = question.$2(answer)),
                      child: Text(_answers.containsKey(index)
                          ? '${question.$1} ${_answers[index]! ? '✓' : '×'}'
                          : question.$1),
                    ),
                ]),
              ],
              const Divider(),
              for (final song in shown)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(song.title),
                    subtitle: _quiz == _Quiz.difficulty && _picked != null
                        ? Text('${_difficulty(song)}')
                        : null,
                    trailing: _picked == null
                        ? null
                        : (song == answer ? const Icon(Icons.check) : null),
                    onTap: _picked == null ? () => _pick(song) : null),
              if (_picked != null) ...[
                Text('${l10n.awmcQuizAnswer} ${answer.title}'),
                Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton(
                        onPressed: () => setState(_newRound),
                        child: Text(l10n.flowNextRound))),
              ],
            ],
          ]),
    );
  }
}
