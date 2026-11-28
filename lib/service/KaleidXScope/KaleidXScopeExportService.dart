import 'dart:io';

import 'package:flutter/material.dart';

import '../../entity/DivingFish/Song.dart';
import '../../entity/KaleidXScope/KaleidXScopeGate.dart';
import '../../l10n/FeatureLocalizations.dart';
import '../../l10n/LocalizationsExtension.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppTheme.dart';
import '../../utils/CoverUtil.dart';
import '../../utils/KaleidDateUtil.dart';
import '../../utils/PosterExportUtil.dart';
import '../../utils/StringUtil.dart';
import '../../widgets/ExportStatsUi.dart';
import '../../widgets/SmoothLinearProgressIndicator.dart';

/// 万花镜（KALEIDXSCOPE）总览与单门攻略进度海报导出服务。
class KaleidXScopeExportService {
  KaleidXScopeExportService._();

  static const double _width = 1080;
  static const int _maxPoolSongs = 24;

  static Future<File?> convertOverviewToImage(
    BuildContext context, {
    required List<({String color, String title, String? asset})> gates,
    ExportImageTheme theme = ExportImageTheme.light,
    Best50ExportBackground background = Best50ExportBackground.none,
    int? jpegQuality,
  }) =>
      PosterExportUtil.captureAndSave(
        context,
        width: _width,
        filePrefix: 'chiffonmai_kaleidxscope_overview',
        subDir: '万花镜',
        songIds: const [],
        background: background,
        jpegQuality: jpegQuality,
        logTag: 'KaleidOverviewExport',
        builder: (overlayContext) => buildOverviewExportWidget(
          overlayContext,
          gates: gates,
          theme: theme,
          background: background,
        ),
      );

  static Future<File?> convertGateToImage(
    BuildContext context, {
    required KaleidXScopeGate gate,
    required String doorTitle,
    required String gateColorKey,
    required Color accentColor,
    String? assetPath,
    String? prerequisite,
    String? keyRequirement,
    String? track1,
    String? track2,
    String? track3,
    required Map<int, Song> songMap,
    required List<int> poolIds,
    required Set<String> markedIds,
    required bool markable,
    ExportImageTheme theme = ExportImageTheme.light,
    Best50ExportBackground background = Best50ExportBackground.none,
    int? jpegQuality,
  }) =>
      PosterExportUtil.captureAndSave(
        context,
        width: _width,
        filePrefix: 'chiffonmai_kaleidxscope_$gateColorKey',
        subDir: '万花镜',
        songIds: [
          for (final s in gate.specialSongs) '${s.songId}',
          for (final id in poolIds.take(_maxPoolSongs)) '$id',
        ],
        background: background,
        jpegQuality: jpegQuality,
        logTag: 'KaleidGateExport',
        builder: (overlayContext) => buildGateExportWidget(
          overlayContext,
          gate: gate,
          doorTitle: doorTitle,
          gateColorKey: gateColorKey,
          accentColor: accentColor,
          assetPath: assetPath,
          prerequisite: prerequisite,
          keyRequirement: keyRequirement,
          track1: track1,
          track2: track2,
          track3: track3,
          songMap: songMap,
          poolIds: poolIds,
          markedIds: markedIds,
          markable: markable,
          theme: theme,
          background: background,
        ),
      );

  static Widget buildOverviewExportWidget(
    BuildContext context, {
    required List<({String color, String title, String? asset})> gates,
    ExportImageTheme theme = ExportImageTheme.light,
    Best50ExportBackground background = Best50ExportBackground.none,
  }) {
    return ExportPage(
      theme: theme,
      background: background,
      width: _width,
      padding: const EdgeInsets.all(36),
      child: Builder(
        builder: (context) {
          final c = ExportPalette.of(context);
          final rows = <List<({String color, String title, String? asset})>>[];
          for (var i = 0; i < gates.length; i += 2) {
            rows.add(gates.sublist(i, (i + 2).clamp(0, gates.length)));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ExportPosterHeader(
                title: 'KALEIDXSCOPE',
                caption: '万花镜门扉一览',
                scale: 0.65,
              ),
              const SizedBox(height: 28),
              for (final (rIndex, row) in rows.indexed) ...[
                if (rIndex > 0) const SizedBox(height: 16),
                Row(
                  children: [
                    for (var i = 0; i < 2; i++) ...[
                      if (i > 0) const SizedBox(width: 16),
                      Expanded(
                        child: i < row.length
                            ? _gateOverviewTile(context, row[i], c)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static Widget _gateOverviewTile(
    BuildContext context,
    ({String color, String title, String? asset}) gate,
    ExportPalette c,
  ) {
    final accent = AppColors.kaleidGateAccent(gate.color, c.brightness) ?? c.accent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: gate.asset != null
                ? Image.asset(gate.asset!, fit: BoxFit.contain)
                : Icon(
                    gate.color == 'error'
                        ? Icons.error_outline
                        : Icons.door_back_door_outlined,
                    size: 56,
                    color: accent,
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            context.featureText(gate.title),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: c.ink,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildGateExportWidget(
    BuildContext context, {
    required KaleidXScopeGate gate,
    required String doorTitle,
    required String gateColorKey,
    required Color accentColor,
    String? assetPath,
    String? prerequisite,
    String? keyRequirement,
    String? track1,
    String? track2,
    String? track3,
    required Map<int, Song> songMap,
    required List<int> poolIds,
    required Set<String> markedIds,
    required bool markable,
    ExportImageTheme theme = ExportImageTheme.light,
    Best50ExportBackground background = Best50ExportBackground.none,
  }) {
    return ExportPage(
      theme: theme,
      background: background,
      width: _width,
      padding: const EdgeInsets.all(36),
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final c = ExportPalette.of(context);
          final twoStages = gateColorKey == 'final';
          final currentPhases = [
            for (final ch in gate.challenges)
              if (KaleidDateUtil.currentPhase([ch]) case final p?)
                (name: ch.name, phase: p),
          ];
          final markedCount =
              poolIds.where((id) => markedIds.contains('$id')).length;
          final shownPool = poolIds.take(_maxPoolSongs).toList(growable: false);
          final omittedPool = poolIds.length - shownPool.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExportPosterHeader(
                title: doorTitle,
                caption: 'KALEIDXSCOPE',
                scale: 0.65,
              ),
              const SizedBox(height: 28),
              ExportStatsPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (assetPath != null)
                          Container(
                            width: 248,
                            height: 112,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Image.asset(assetPath, fit: BoxFit.contain),
                          ),
                        if (assetPath != null) const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (currentPhases.isEmpty)
                                ExportStatBlock(
                                  label: l10n.flowCurrentPhase,
                                  value: l10n.flowNoActiveChallengesCheckTheScheduleBelow,
                                  valueSize: 20,
                                )
                              else
                                for (final (idx, item) in currentPhases.indexed) ...[
                                  if (idx > 0) const SizedBox(height: 10),
                                  ExportHeroBlock(
                                    label: currentPhases.length > 1
                                        ? item.name
                                        : l10n.flowCurrentPhase,
                                    value: twoStages && item.phase.target != null
                                        ? 'LIFE ${item.phase.lifeTarget} / ${item.phase.target}'
                                        : 'LIFE ${item.phase.lifeTarget}',
                                    caption:
                                        '${item.phase.difficulty} · ${KaleidDateUtil.range(item.phase.startDate, item.phase.endDate)}',
                                  ),
                                ],
                              if (markable) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      l10n.flowMarkedP0P1(
                                          '$markedCount', '${poolIds.length}'),
                                      style: AppTheme.number(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: c.ink,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                SmoothLinearProgressIndicator(
                                  value: poolIds.isEmpty
                                      ? 0
                                      : markedCount / poolIds.length,
                                  minHeight: 8,
                                  color: accentColor,
                                  backgroundColor: c.track,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ExportSectionTitle(l10n.flowGuide),
              const SizedBox(height: 12),
              ExportStatsPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _guideLine(c, '1 · ${l10n.flowGateConditions}',
                        prerequisite ?? l10n.flowNotSet3),
                    const SizedBox(height: 10),
                    _guideLine(
                        c, '2 · ${l10n.flowKeyRequiredToChallenge}', keyRequirement ?? '-'),
                    const SizedBox(height: 10),
                    _guideLine(
                      c,
                      '3 · ${l10n.flowKALEIDXSCOPEMode}',
                      [
                        l10n.flowFirstSongP0(track1 ?? l10n.flowNotSet3),
                        if (track2 != null) l10n.flowSecondSongP0(track2),
                        if (track3 != null) l10n.flowThirdSongP0(track3),
                      ].join(' / '),
                    ),
                  ],
                ),
              ),
              if (gate.specialSongs.isNotEmpty) ...[
                const SizedBox(height: 24),
                ExportSectionTitle(l10n.flowHiddenSong),
                const SizedBox(height: 12),
                ExportStatsPanel(
                  child: Column(
                    children: [
                      for (final (i, sp) in gate.specialSongs.indexed) ...[
                        if (i > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: c.cardBorder),
                          ),
                        _songExportRow(
                          context,
                          songId: sp.songId,
                          song: songMap[sp.songId],
                          caption: switch (sp.role) {
                            'perfect' => l10n.flowPerfectChallengeSong,
                            'reward' => l10n.flowClearRewardSong,
                            _ => l10n.flowHiddenSong,
                          },
                          accent: accentColor,
                          marked: markable && markedIds.contains('${sp.songId}'),
                          c: c,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (shownPool.isNotEmpty) ...[
                const SizedBox(height: 24),
                ExportSectionTitle('${l10n.flowSongPool} · ${poolIds.length}'),
                const SizedBox(height: 12),
                ExportStatsPanel(
                  child: Column(
                    children: [
                      for (final (i, id) in shownPool.indexed) ...[
                        if (i > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: c.cardBorder),
                          ),
                        _songExportRow(
                          context,
                          songId: id,
                          song: songMap[id],
                          accent: accentColor,
                          marked: markable && markedIds.contains('$id'),
                          c: c,
                        ),
                      ],
                      if (omittedPool > 0) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: c.cardBorder),
                        ),
                        Text(
                          '... 共 ${poolIds.length} 首（已展示前 ${shownPool.length} 首）',
                          style: TextStyle(fontSize: 17, color: c.muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static Widget _guideLine(ExportPalette c, String title, String content) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w800, color: c.ink)),
          const SizedBox(height: 3),
          Text(content, style: TextStyle(fontSize: 17, color: c.muted)),
        ],
      );

  static Widget _songExportRow(
    BuildContext context, {
    required int songId,
    Song? song,
    String? caption,
    required Color accent,
    required bool marked,
    required ExportPalette c,
  }) {
    final l10n = context.l10n;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CoverUtil.buildCoverWidgetWithContext(context, '$songId', 48),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (caption != null)
                Text(
                  caption,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: accent),
                ),
              Text(
                song?.title ?? l10n.flowSongIDP02('$songId'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w700, color: c.ink),
              ),
              if (song != null) ...[
                const SizedBox(height: 3),
                Text(
                  '${song.type == 'DX' ? 'DX' : 'ST'} | ${StringUtil.formatVersion2WithFlag(song.basicInfo.from, song.isExtra)}',
                  style: TextStyle(fontSize: 15, color: c.muted),
                ),
              ],
            ],
          ),
        ),
        if (marked)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: c.positive.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
            ),
            child: Text(
              l10n.featureDone,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: c.positive),
            ),
          ),
      ],
    );
  }
}
