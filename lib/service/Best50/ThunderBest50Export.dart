import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constant/AppLinks.dart';
import '../../constant/CacheKeyConstant.dart';
import '../../utils/CurrentDataSourceNotifier.dart';
import '../../utils/ExportUserInfoWidget.dart';
import '../../widgets/B50GameCardWidget.dart';
import '../../widgets/ExportStatsUi.dart';

/// 雷霆长图：保持单卡的导出尺寸，个人信息、统计和元信息合并成紧凑的说明卡。
/// 横版说明卡放在队首，竖版放在顶部，全部谱面连续排列而不再分成两个网格。
class ThunderBest50Export {
  static const double cardWidth = 335;
  static const double gap = 6;
  static const double verticalWidth = 375;

  static double widthFor(int count, bool vertical) => vertical
      ? verticalWidth
      : 40 + verticalWidth + gap + count * (cardWidth + gap);

  static Future<Widget> build({
    required ExportImageTheme theme,
    required String title,
    required bool vertical,
    required int count,
    required Widget Function(int index) cardBuilder,
    required String statistics,
    bool showUserInfo = true,
    String? warning,
    String? sortLabel,
  }) async {
    final user = showUserInfo
        ? await ExportUserInfoWidget.loadUserInfo()
        : <String, dynamic>{};
    final prefs = await SharedPreferences.getInstance();
    final source = RefreshDataSource.displayNameOfKey(
        prefs.getString(CacheKeyConstant.lastDataSource));
    final now = DateTime.now();
    final time =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final avatar = user['avatarUrl'] as String? ?? '';
    final info = SizedBox(
      width: vertical ? cardWidth : verticalWidth,
      child: ExportHeroSurface(
        radius: 16,
        padding: const EdgeInsets.all(18),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.45),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 28, height: 1.15, fontWeight: FontWeight.w900)),
              Text(appL10n.flowThunderMode,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8))),
              if (showUserInfo) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Container(
                    width: 56,
                    height: 56,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: avatar.isEmpty
                        ? Icon(Icons.person_rounded,
                            size: 40, color: ExportPalette.light.muted)
                        : CachedNetworkImage(
                            imageUrl: avatar, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text('${user['nickname'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700))),
                ]),
              ],
              const SizedBox(height: 12),
              Text(statistics),
              if (sortLabel != null && sortLabel.isNotEmpty)
                Text(appL10n.flowOrderP0((sortLabel).toString())),
              if (warning != null && warning.isNotEmpty)
                Text(warning, style: const TextStyle(color: Color(0xFFFFB4AB))),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                    height: 1, color: Colors.white.withValues(alpha: 0.25)),
              ),
              Text(
                appL10n.flowSourceP0ExportedP1GeneratedByChiffonMai((source).toString(), (time).toString(), (AppLinks.qqGroupNumber).toString()),
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      ),
    );
    final cards = List.generate(
        count,
        (index) => SizedBox(
              width: cardWidth,
              height: B50GameCardWidget.exportCardHeight,
              child: cardBuilder(index),
            ));
    return ExportPage(
      theme: theme,
      width: widthFor(count, vertical),
      padding: const EdgeInsets.all(20),
      child: vertical
          ? Column(mainAxisSize: MainAxisSize.min, children: [
              info,
              for (final card in cards) ...[const SizedBox(height: gap), card],
            ])
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  info,
                  for (final card in cards) ...[
                    const SizedBox(width: gap),
                    card
                  ],
                ]),
    );
  }
}
