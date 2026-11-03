import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/utils/ThemeManager.dart';
import 'AppDesignTokens.dart';
import '../widgets/GuessSettingsUi.dart';

/**
 * 通用Widget工具类
 * 所有背景、标题、按钮组件均已支持暗色模式自动切换
 */
class CommonWidgetUtil {
  /**
   * 构建通用背景Widget（主题感知 — 暗色模式自动变暗）
   * 层级1：基础背景图 - 占满整个屏幕
   */
  static Widget buildCommonBgWidget() {
    return const _ThemeAwareBgWidget();
  }

  /**
   * 构建通用装饰背景Widget（主题感知 — 暗色模式降低透明度并变暗）
   * 层级2：chiffon 装饰图 - 居中显示，轻微向上偏移
   */
  static Widget buildCommonChiffonBgWidget(BuildContext context) {
    return _ThemeAwareChiffonWidget();
  }

  /**
   * 构建通用标题Widget（主题感知）
   */
  static Widget buildCommonTitleWidget(String title) {
    return _ThemeAwareTitleWidget(title: title);
  }

  /**
   * 构建通用返回按钮Widget（主题感知）
   */
  static Widget buildCommonBackButtonWidget(BuildContext context) {
    return _ThemeAwareBackButtonWidget();
  }

  /**
   * 构建猜歌通用设置Widget
   *
   * 注意：这里**不再**有 onReset 形参。原先它是个从未被使用的死参数，
   * 各页面因此各自手写一份「重置所有设置」按钮和默认值字面量，
   * 结果歌曲片段页那份漏了播放时长。默认值现在统一来自
   * `GuessChartCommonSettingsService.defaultSettings()`。
   */
  static Widget buildGuessChartSettingsWidget(
    BuildContext context,
    List<String> allVersions,
    List<String> allGenres,
    List<String> selectedVersions,
    double masterMinDx,
    double masterMaxDx,
    List<String> selectedGenres,
    int maxGuesses,
    int timeLimit,
    Function(List<String>) onVersionsChanged,
    Function(double, double) onMasterDxRangeChanged,
    Function(List<String>) onGenresChanged,
    Function(int) onMaxGuessesChanged,
    Function(int) onTimeLimitChanged,
    {
    // 定数范围这一节的标题。
    //
    // 默认面向「按 MASTER 难度定数筛选」的模式（无提示 / 曲绘 / 模糊曲绘 /
    // 歌曲片段 / 别名 / 开字母），那里确实只看 MASTER 的定数。
    // 但**谱面片段猜歌**是按「难度随机池」抽谱的，判定用的是池内各难度
    // 各自的定数，写「MASTER定数范围」会让用户以为只按 MASTER 筛 —— 与实际不符，
    // 所以那一页传「定数范围」。
    String dxRangeTitle = 'MASTER定数范围',
    // 定数范围下方的补充说明（可选），用于点明判定口径。
    String? dxRangeHint,
    // 页面里铺成白卡片；对话框本身就是卡片，直接平铺。
    bool card = false,
  }) {
    final maxGuessesText =
        maxGuesses == 0 || maxGuesses == 20 ? '无限制' : '$maxGuesses 次';
    final timeLimitText =
        timeLimit == 0 || timeLimit == 180 ? '无限制' : '$timeLimit 秒';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GuessSettingSection(
          card: card,
          title: '题库范围',
          icon: Icons.library_music_rounded,
          children: [
            GuessMultiSelectTile(
              label: '版本',
              items: allVersions,
              selected: selectedVersions,
              formatter: StringUtil.formatVersion2,
              onChanged: onVersionsChanged,
            ),
            GuessMultiSelectTile(
              label: '流派',
              items: allGenres.where((genre) => genre != '宴会場').toList(),
              selected:
                  selectedGenres.where((genre) => genre != '宴会場').toList(),
              onChanged: onGenresChanged,
            ),
            _MasterDxRangeInput(
              title: dxRangeTitle,
              hint: dxRangeHint,
              minValue: masterMinDx,
              maxValue: masterMaxDx,
              onChanged: onMasterDxRangeChanged,
            ),
          ],
        ),
        SizedBox(height: card ? AppDesignTokens.cardGap : 4),
        GuessSettingSection(
          card: card,
          title: '对局规则',
          icon: Icons.flag_rounded,
          children: [
            GuessSliderTile(
              label: '最大猜测次数',
              valueText: maxGuessesText,
              value: maxGuesses == 0 ? 20.0 : maxGuesses.toDouble(),
              min: 1,
              max: 20,
              // divisions 必须是 (max-min) 的约数：19 段步长正好 1，取值 1..20。
              divisions: 19,
              onChanged: (value) {
                onMaxGuessesChanged(value.toInt() == 20 ? 0 : value.toInt());
              },
            ),
            GuessSliderTile(
              label: '时间限制',
              valueText: timeLimitText,
              value: timeLimit == 0 ? 180.0 : timeLimit.toDouble(),
              min: 30,
              max: 180,
              divisions: 15,
              onChanged: (value) {
                int roundedValue = (value.toInt() / 10).round() * 10;
                roundedValue = roundedValue.clamp(30, 180);
                onTimeLimitChanged(roundedValue == 180 ? 0 : roundedValue);
              },
            ),
          ],
        ),
      ],
    );
  }

  // prevent instantiation
  CommonWidgetUtil._();
}

// ============ 内部主题感知组件 ============

/// MASTER 定数范围输入框。
///
/// 必须是 StatefulWidget，且**由它自己持有 TextEditingController**：
/// 原先这个输入框直接建在 `buildGuessChartSettingsWidget` 里，每次外层
/// setState（勾选版本、拖滑块……）都会新建 controller，导致
/// - 用户输入到一半、去点了别的控件 → 输入内容被重置回旧值；
/// - 提交时机是 `onEditingComplete`，只有按回车才生效，点「确定」直接
///   关掉对话框时改动会**静默丢失**（widget 测试里实测 committed=0）。
///
/// 现在改为：controller 由本 State 持有，失焦（onTapOutside）与回车都会提交，
/// 并且 controller 文本只在「外部值变化」时才同步，不会打断用户输入。
class _MasterDxRangeInput extends StatefulWidget {
  const _MasterDxRangeInput({
    required this.title,
    required this.hint,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
  });

  final String title;
  final String? hint;
  final double minValue;
  final double maxValue;
  final Function(double, double) onChanged;

  @override
  State<_MasterDxRangeInput> createState() => _MasterDxRangeInputState();
}

class _MasterDxRangeInputState extends State<_MasterDxRangeInput> {
  static const double _absoluteMin = 1.0;
  static const double _absoluteMax = 15.0;

  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late final FocusNode _minFocus;
  late final FocusNode _maxFocus;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(text: _fmt(widget.minValue));
    _maxController = TextEditingController(text: _fmt(widget.maxValue));
    _minFocus = FocusNode();
    _maxFocus = FocusNode();
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _minFocus.dispose();
    _maxFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _MasterDxRangeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有外部值**真的变了**才回写文本，否则会把用户正在输入的内容抹掉
    // （例如「14.」这种还没输入完、暂不非法的中间态）。
    if (widget.minValue != oldWidget.minValue && !_minFocus.hasFocus) {
      _minController.text = _fmt(widget.minValue);
    }
    if (widget.maxValue != oldWidget.maxValue && !_maxFocus.hasFocus) {
      _maxController.text = _fmt(widget.maxValue);
    }
  }

  static String _fmt(double v) => v.toStringAsFixed(1);

  /// 提交一个输入框的值。非法输入（空/非数字/越界）一律**回滚成当前外部值**，
  /// 而不是悄悄丢弃——否则用户会看着一个和实际生效值不一致的数字。
  void _commit({required bool isMin}) {
    final TextEditingController controller = isMin ? _minController : _maxController;
    final double fallback = isMin ? widget.minValue : widget.maxValue;
    final double? parsed = double.tryParse(controller.text.trim());
    final bool valid = parsed != null &&
        parsed >= _absoluteMin &&
        parsed <= _absoluteMax;
    if (!valid) {
      controller.text = _fmt(fallback);
      return;
    }
    final double newMin = isMin ? parsed : widget.minValue;
    final double newMax = isMin ? widget.maxValue : parsed;
    // 归一化显示（14 -> 14.0），并保持 min <= max：
    // 若用户把最小值填得比最大值还大，就把最大值一起顶上去。
    if (newMin > newMax) {
      final double unified = isMin ? newMin : newMax;
      _minController.text = _fmt(unified);
      _maxController.text = _fmt(unified);
      widget.onChanged(unified, unified);
      return;
    }
    controller.text = _fmt(parsed);
    widget.onChanged(newMin, newMax);
  }

  Widget _field({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isMin,
    required ColorScheme scheme,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      borderSide: BorderSide.none,
    );
    return TextField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      controller: controller,
      focusNode: focusNode,
      textAlign: TextAlign.center,
      onSubmitted: (_) => _commit(isMin: isMin),
      onTapOutside: (_) => _commit(isMin: isMin),
      style: AppTheme.number(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppSurfaces.inset(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hintStyle =
        TextStyle(fontSize: 12, height: 1.4, color: scheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title,
            style: TextStyle(fontSize: 13.5, color: scheme.onSurface)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _field(
                controller: _minController,
                focusNode: _minFocus,
                isMin: true,
                scheme: scheme,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('至',
                  style: TextStyle(
                      fontSize: 13, color: scheme.onSurfaceVariant)),
            ),
            Expanded(
              child: _field(
                controller: _maxController,
                focusNode: _maxFocus,
                isMin: false,
                scheme: scheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('可填 1.0 至 15.0，点其它位置或按回车生效', style: hintStyle),
        if (widget.hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(widget.hint!, style: hintStyle),
          ),
      ],
    );
  }
}

/// 主题感知的背景图组件（StatelessWidget）
/// 性能：用 Stack + 半透明覆层代替 ColorFiltered + BlendMode.darken，避免 saveLayer
/// - 浅色模式：白色半透明覆层使背景图变成若隐若现的纹理（不透明度用户可调）
/// - 深色模式：深色半透明覆层压暗背景图
/// - 纯黑模式：隐藏背景图，显示纯黑底色
/// - 用户自定义背景图：ThemeManager.customBackgroundPath 非空时优先使用本地文件
class _ThemeAwareBgWidget extends StatelessWidget {
  const _ThemeAwareBgWidget();

  @override
  Widget build(BuildContext context) {
    // 用 ListenableBuilder 包裹两个信号：覆层透明度 + 自定义背景图路径
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeManager().lightOverlayNotifier,
        ThemeManager().customBackgroundPathNotifier,
      ]),
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isPureBlack = isDark && ThemeManager().pureBlackEnabled;
        final opacity = ThemeManager().lightOverlayOpacity;
        final overlayAlpha = (opacity * 255).round().clamp(0, 255);
        // 覆层取页面底色而不是纯白，与 ThemeAwareBackground 一致。
        final lightOverlay =
            Theme.of(context).colorScheme.surface.withAlpha(overlayAlpha);
        final darkOverlay = Color.fromARGB(overlayAlpha, 15, 15, 28);

        // 解析背景图层：自定义路径 -> Image.file，否则 -> Image.asset
        final customPath = ThemeManager().customBackgroundPath;
        Widget bgImage;
        if (customPath != null) {
          bgImage = Image.file(
            File(customPath),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          );
        } else {
          bgImage = Image.asset(
            'assets/background.png',
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // 纯黑模式：不加载背景图，只放纯黑底色
            if (isPureBlack)
              const Positioned.fill(child: ColoredBox(color: Colors.black))
            else ...[
              Positioned.fill(child: bgImage),
              // 浅色/深色均添加覆层：浅色用白色洗淡，深色用暗色压暗
              if (isDark)
                Positioned.fill(child: ColoredBox(color: darkOverlay))
              else
                Positioned.fill(child: ColoredBox(color: lightOverlay)),
            ],
          ],
        );
      },
    );
  }
}

/// 主题感知的 chiffon 装饰组件（StatelessWidget）
/// - 浅色/深色模式：使用 ThemeManager.chiffonOpacity 控制装饰图透明度
/// - 纯黑模式：完全隐藏装饰层
///
/// ⚠️ 这里**不再**往装饰图上铺那层 `(10,10,25)` 的矩形覆层，原因同
/// `ThemeAwareBackground._ChiffonImage`：装饰图是透明底的整屏图，覆层却是
/// 一块实心矩形 —— 它跟装饰图自己的透明度无关（装饰图默认 0，覆层照样满屏画），
/// 于是「什么都没开」时整页也会被多压暗一层；`BoxFit.cover` 下更是铺满全屏。
/// 装饰图的浓淡只由它自己的滑杆控制。
class _ThemeAwareChiffonWidget extends StatelessWidget {
  const _ThemeAwareChiffonWidget();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPureBlack = isDark && ThemeManager().pureBlackEnabled;

    // 纯黑模式：不显示装饰图
    if (isPureBlack) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: ThemeManager().chiffonOpacityNotifier,
      builder: (context, _) {
        final opacity = ThemeManager().chiffonOpacity;
        // 隐藏时直接不占位：省掉一张全屏图的布局/解码，也不会留下任何覆层
        if (opacity <= 0) return const SizedBox.shrink();

        return Center(
          child: Transform.translate(
            offset: Offset(0, -MediaQuery.of(context).size.height * 0.03),
            child: Image.asset(
              'assets/chiffon2.png',
              fit: BoxFit.cover,
              gaplessPlayback: true,
              opacity: AlwaysStoppedAnimation(opacity),
            ),
          ),
        );
      },
    );
  }
}

/// 主题感知的标题组件
class _ThemeAwareTitleWidget extends StatefulWidget {
  final String title;
  const _ThemeAwareTitleWidget({required this.title});

  @override
  State<_ThemeAwareTitleWidget> createState() => _ThemeAwareTitleWidgetState();
}

class _ThemeAwareTitleWidgetState extends State<_ThemeAwareTitleWidget> {
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final textColor = AppColors.primaryText(brightness);
    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          widget.title,
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

/// 主题感知的返回按钮组件
class _ThemeAwareBackButtonWidget extends StatefulWidget {
  const _ThemeAwareBackButtonWidget();

  @override
  State<_ThemeAwareBackButtonWidget> createState() => _ThemeAwareBackButtonWidgetState();
}

class _ThemeAwareBackButtonWidgetState extends State<_ThemeAwareBackButtonWidget> {
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final iconColor = AppColors.primaryText(brightness);
    return Positioned(
      top: 40,
      left: 10,
      child: GestureDetector(
        onTap: () {
          debugPrint('返回按钮被点击');
          Navigator.pop(context);
        },
        child: Container(
          padding: EdgeInsets.all(16),
          color: Colors.transparent,
          child: Icon(Icons.arrow_back, color: iconColor, size: 24),
        ),
      ),
    );
  }
}
