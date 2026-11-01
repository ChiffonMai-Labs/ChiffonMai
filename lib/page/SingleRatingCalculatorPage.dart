import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../widgets/AppUi.dart';
import '../widgets/BackgroundPageScaffold.dart';

/// 单曲 Rating 计算。
///
/// 2026-11 重构：输入合法时**实时出结果**（不再需要点「计算」），
/// 并提供常用达成率快捷填入；乘数表与旧版逐项一致，当前命中的那一档高亮。
/// 算法沿用旧版：`floor(定数 × 乘数 × min(达成率, 100.5))`。
class SingleRatingCalculator extends StatefulWidget {
  const SingleRatingCalculator({super.key});

  @override
  State<SingleRatingCalculator> createState() => _SingleRatingCalculatorState();
}

class _SingleRatingCalculatorState extends State<SingleRatingCalculator> {
  late final TextEditingController _difficultyController =
      TextEditingController();
  late final TextEditingController _completionController =
      TextEditingController();

  String? _difficultyError;
  String? _completionError;

  // 舞萌DX 完成度-评级-乘数对照表（与旧版一致）
  static const List<Map<String, dynamic>> maimaiRatingMultiplier = [
    {"completion": 100.5, "rating": "SSS+", "multiplier": 0.224},
    {"completion": 100.4999, "rating": "SSS", "multiplier": 0.222},
    {"completion": 100.0, "rating": "SSS", "multiplier": 0.216},
    {"completion": 99.9999, "rating": "SS+", "multiplier": 0.214},
    {"completion": 99.5, "rating": "SS+", "multiplier": 0.211},
    {"completion": 99.0, "rating": "SS", "multiplier": 0.208},
    {"completion": 98.9999, "rating": "S+", "multiplier": 0.206},
    {"completion": 98.0, "rating": "S+", "multiplier": 0.203},
    {"completion": 97.0, "rating": "S", "multiplier": 0.2},
    {"completion": 96.9999, "rating": "AAA", "multiplier": 0.176},
    {"completion": 94.0, "rating": "AAA", "multiplier": 0.168},
    {"completion": 90.0, "rating": "AA", "multiplier": 0.152},
    {"completion": 80.0, "rating": "A", "multiplier": 0.136},
    {"completion": 79.9999, "rating": "BBB", "multiplier": 0.128},
    {"completion": 75.0, "rating": "BBB", "multiplier": 0.120},
    {"completion": 70.0, "rating": "BB", "multiplier": 0.112},
    {"completion": 60.0, "rating": "B", "multiplier": 0.096},
    {"completion": 50.0, "rating": "C", "multiplier": 0.08},
    {"completion": 40.0, "rating": "D", "multiplier": 0.064},
    {"completion": 30.0, "rating": "D", "multiplier": 0.048},
    {"completion": 20.0, "rating": "D", "multiplier": 0.032},
    {"completion": 10.0, "rating": "D", "multiplier": 0.016},
  ];

  static const List<String> _quickCompletions = [
    '100.5',
    '100.0',
    '99.5',
    '99.0',
    '98.0',
    '97.0',
  ];

  @override
  void dispose() {
    _difficultyController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  String? _validate(String text, double min, double max, String label) {
    if (text.trim().isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || !value.isFinite) return '请输入有效的$label';
    if (value < min || value > max) return '$label必须在$min到$max之间';
    return null;
  }

  void _onInputChanged() {
    setState(() {
      _difficultyError = _validate(_difficultyController.text, 1, 15, '歌曲定数');
      _completionError = _validate(_completionController.text, 0, 101, '达成率');
    });
  }

  void _fillCompletion(String value) {
    _completionController.text = value;
    _completionController.selection =
        TextSelection.collapsed(offset: value.length);
    _onInputChanged();
  }

  /// 输入完整且合法时返回 (评级, 乘数, 单曲 Rating, 命中行下标)。
  ({String rating, double multiplier, double singleRating, int row})?
      _result() {
    if (_difficultyError != null || _completionError != null) return null;
    final difficulty = double.tryParse(_difficultyController.text);
    final completion = double.tryParse(_completionController.text);
    if (difficulty == null || completion == null) return null;

    // 特别处理：如果达成率大于100.5，则按100.5计算
    final adjusted = completion > 100.5 ? 100.5 : completion;
    final row = maimaiRatingMultiplier
        .indexWhere((item) => adjusted >= (item['completion'] as double));
    final rating =
        row < 0 ? 'D' : maimaiRatingMultiplier[row]['rating'] as String;
    final multiplier = row < 0
        ? 0.016
        : maimaiRatingMultiplier[row]['multiplier'] as double;
    final singleRating = (difficulty * multiplier * adjusted).floorToDouble();
    return (
      rating: rating,
      multiplier: multiplier,
      singleRating: singleRating,
      row: row,
    );
  }

  /// 等效定数对照（与旧版一致：超过 15.0 的不显示）。
  List<String> _equivalents(double singleRating) {
    const tiers = [
      ('100.5%', 0.224, 100.5),
      ('100.0%', 0.216, 100.0),
      ('99.5%', 0.211, 99.5),
      ('99.0%', 0.208, 99.0),
    ];
    final out = <String>[];
    for (final (label, multiplier, completion) in tiers) {
      final equivalent = singleRating / (multiplier * completion);
      if (equivalent > 15.0) continue;
      out.add('${equivalent.toStringAsFixed(1)} 的 $label');
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final result = _result();
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return BackgroundPageScaffold(
      title: '单曲Rating计算',
      resizeToAvoidBottomInset: true,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppDesignTokens.gutter, 4,
              AppDesignTokens.gutter, 24 + bottomInset),
          children: [
            _buildResultCard(result),
            const SizedBox(height: AppDesignTokens.cardGap),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNumberField(
                    label: '歌曲定数',
                    hint: '1.0 – 15.0',
                    controller: _difficultyController,
                    error: _difficultyError,
                    pattern: r'^\d*\.?\d{0,1}',
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    label: '达成率',
                    hint: '0 – 101',
                    suffix: '%',
                    controller: _completionController,
                    error: _completionError,
                    pattern: r'^\d*\.?\d{0,4}',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final v in _quickCompletions)
                        _QuickChip(
                          label: v,
                          selected: _completionController.text == v,
                          onTap: () => _fillCompletion(v),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesignTokens.cardGap),
            _buildMultiplierTable(result?.row),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? error,
    required String pattern,
    String? suffix,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: (_) => _onInputChanged(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(pattern))],
          style: AppTheme.number(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                fontSize: 15, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
            suffixText: suffix,
            errorText: error,
            filled: true,
            fillColor: AppSurfaces.inset(context),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(
      ({String rating, double multiplier, double singleRating, int row})?
          result) {
    final scheme = Theme.of(context).colorScheme;
    final onCard = scheme.onInverseSurface;
    final muted = onCard.withValues(alpha: 0.72);
    final equivalents = result != null && result.singleRating > 0
        ? _equivalents(result.singleRating)
        : const <String>[];

    return EmphasisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('单曲 Rating', style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                result == null ? '—' : result.singleRating.toInt().toString(),
                style: AppTheme.number(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: onCard,
                    height: 1),
              ),
              const SizedBox(width: 12),
              if (result != null) RankBadge(rank: result.rating, fontSize: 16),
              const Spacer(),
              if (result != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('乘数', style: TextStyle(fontSize: 11, color: muted)),
                    Text(result.multiplier.toString(),
                        style: AppTheme.number(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: onCard)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result == null
                ? '填好定数和达成率后自动计算 · 单曲 Rating = 定数 × 乘数 × 达成率（取整）'
                : '单曲 Rating = 定数 × 乘数 × 达成率（取整）',
            style: TextStyle(fontSize: 12, color: muted),
          ),
          if (equivalents.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('等效定数对照', style: TextStyle(fontSize: 12, color: muted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in equivalents)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: onCard.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
                    ),
                    child: Text('相当于 $e',
                        style: TextStyle(fontSize: 12, color: onCard)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMultiplierTable(int? highlightRow) {
    final scheme = Theme.of(context).colorScheme;
    TextStyle head() => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: scheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(
          title: '乘数对照表',
          subtitle: '达成率不低于左列时使用对应乘数；超过 100.5% 按 100.5% 计算',
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text('达成率 ≥', style: head())),
                    Expanded(child: Text('评级', style: head())),
                    Expanded(
                        child: Text('乘数',
                            style: head(), textAlign: TextAlign.end)),
                  ],
                ),
              ),
              for (var i = 0; i < maimaiRatingMultiplier.length; i++)
                AnimatedContainer(
                  duration: AppDesignTokens.motion(
                      context, AppDesignTokens.fastMotion),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: i == highlightRow
                        ? scheme.primaryContainer
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${maimaiRatingMultiplier[i]['completion']}',
                          style: AppTheme.number(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: i == highlightRow
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurface),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: RankBadge(
                              rank: maimaiRatingMultiplier[i]['rating']
                                  as String,
                              fontSize: 11),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${maimaiRatingMultiplier[i]['multiplier']}',
                          textAlign: TextAlign.end,
                          style: AppTheme.number(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: i == highlightRow
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : AppSurfaces.inset(context),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            '$label%',
            style: AppTheme.number(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
