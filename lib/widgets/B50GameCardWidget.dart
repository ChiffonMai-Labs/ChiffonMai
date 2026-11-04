import 'package:flutter/material.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/CoverUtil.dart';
import '../utils/ExportImageTheme.dart';
import '../utils/ThemeManager.dart';

/// [B50GameCardWidget] 的配色。
class B50CardPalette {
  final Color card;
  final Color strip;
  final Color ink;
  final Color muted;
  final Color border;

  /// 没有连击 / 同步时的灰章不透明度。灰章是浅色图，在深色卡片上要压暗。
  final double emptyGradeOpacity;

  const B50CardPalette({
    required this.card,
    required this.strip,
    required this.ink,
    required this.muted,
    required this.border,
    this.emptyGradeOpacity = 1,
  });

  /// 浅色白卡片。
  static const B50CardPalette light = B50CardPalette(
    card: Colors.white,
    strip: Color(0xFFF0F4F3),
    ink: Color(0xFF16201F),
    muted: Color(0xFF5F6B6A),
    border: Color(0x14000000),
  );

  /// 导出图片用：跟随导出抽屉里选的主题，不跟随 App。
  factory B50CardPalette.forExport(ExportPalette c) {
    if (c.isLight) return light;
    return B50CardPalette(
      card: c.panel,
      strip: c.inset,
      ink: c.ink,
      muted: c.muted,
      border: c.cardBorder,
      emptyGradeOpacity: 0.4,
    );
  }

  /// 页面上用：跟随 App 当前的浅色 / 深色 / 纯黑设置。
  factory B50CardPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness != Brightness.dark) return light;
    return B50CardPalette.dark(theme.colorScheme,
        pureBlack: ThemeManager().pureBlackEnabled);
  }

  /// 深色取主题的容器色，带一点用户的主题色；
  /// 纯黑的卡片本身就是黑色，靠细描边和凹槽勾出边界。
  factory B50CardPalette.dark(ColorScheme scheme, {bool pureBlack = false}) {
    return B50CardPalette(
      card: pureBlack ? Colors.black : scheme.surfaceContainer,
      strip: pureBlack ? const Color(0xFF161616) : scheme.surfaceContainerHigh,
      ink: pureBlack ? Colors.white : scheme.onSurface,
      muted: pureBlack ? const Color(0xFFA6A6A6) : scheme.onSurfaceVariant,
      border: pureBlack ? const Color(0x33FFFFFF) : const Color(0x14FFFFFF),
      emptyGradeOpacity: 0.4,
    );
  }
}

/// Best50 系列卡片通用 widget，用于导出图片和页面的双列显示模式。
/// 卡片结构：上方是带难度色描边的曲绘 + 歌名 + 达成率 + 定数和 RA + DX 分，
/// 下方凹槽放谱面 ID + 类型 + 评级 + FC + FS + 星数。
///
/// 字号常量的标定基准是「导出图片单卡实际可见宽度」[refCardWidth] = 335，
/// 通过 [scale] 适配不同使用场景：
///   * 导出图片时 `scale = 1.0`（335 就是照它标定的）；
///   * 页面显示时**默认 [autoScale]**：字号按卡片**渲染时的实际宽度**换算，
///     基准是 [screenRefCardWidth] —— 屏幕口径**故意**比导出基准大约 8.8%
///     （统一口径前页面拿屏幕宽度估格子宽，比真实格子大 ~9%，见常量注释）。
class B50GameCardWidget extends StatelessWidget {
  /// 字号换算的基准卡宽（与导出图片同源）。
  ///
  /// 这个数**不能改**：所有字号常量（[_kSongName] 等）都是照着它标定的。
  static const double refCardWidth = 335.0;

  /// **屏幕口径**的字号换算基准宽度：`335 / 1.088 ≈ 308`。
  ///
  /// 比导出基准 [refCardWidth] 小 8.8% —— 分母越小，字号 / 曲绘 / 角标越大，
  /// 这是**故意**的：卡片若按「真实格子宽 / 335」换算，会比用户熟悉的版本
  /// 整体小一圈（反馈："卡片里的曲绘、评级连击同步图片和文本字号都变小了"）。
  ///
  /// 那 8.8% 正是「统一口径」**之前估宽的水分**：页面按 `screenW` 估格子宽
  /// （`(screenW - screenW * 0.0x) / 2`），没扣容器 padding / 网格间距 ——
  /// 360 屏估 178.2、真实格子 163.4（1.09 倍）。换成真实宽度后卡片内容
  /// 整体小了 ~9%，这里在**屏幕口径**上把这一截还回来。
  ///
  /// 320~480 屏的「真实格子 / 旧估算」实测落在 1.082~1.097，取中值 1.088。
  ///
  /// ⚠️ **导出图片（`scale: 1.0` 的离屏渲染）不走这里**，仍按 [refCardWidth]
  /// 标定；反过来说，页面口径下也别再把 [refCardWidth] 当分母。
  static const double screenRefCardWidth = 308.0;

  /// [scale] 的哨兵值：**按卡片渲染时真实拿到的宽度自适应**。
  ///
  /// 页面显示一律用这个（默认值）。网格格子给卡片的是**紧约束**，卡片根部的
  /// `LayoutBuilder` 拿到的 `maxWidth` 就是它最终的可见宽度，因此
  /// `scale = maxWidth / [screenRefCardWidth]` 永远和实际渲染一致。
  ///
  /// ⚠️ 页面里**别再手算** `((screenW - screenW * 0.0x) / 2) / 335`：容器
  /// padding / 边距 / 网格间距都没算进去，和真实格子对不上。
  ///
  /// 导出图片时显式传 `1.0`（基准宽度 [refCardWidth] 就是照它标定的）。
  static const double autoScale = 0.0;

  /// 把 [scale] 换算成真正生效的缩放值。
  ///
  /// * `scale > 0`：[scale] 本身（导出图片传 1.0）；
  /// * `scale <= 0`（[autoScale]）：`[boxWidth] / [screenRefCardWidth]`，
  ///   其中 [boxWidth] 是卡片渲染时**真实拿到的宽度**。
  ///
  /// ⚠️ [boxWidth] 只能是**渲染时**拿到的宽度（`LayoutBuilder` 的 `maxWidth`）：
  /// 拿屏幕宽度 / 网格外层宽度「估」出来的值都会偏大（统一口径前偏大 ~9%）。
  static double resolveScale(double scale, double boxWidth) {
    if (scale > 0) return scale;
    return (boxWidth.isFinite && boxWidth > 0)
        ? boxWidth / screenRefCardWidth
        : 1.0;
  }

  /// 卡片的固定设计宽高比，调整内部分区占比时保持此值不变。
  ///
  /// 页面摆放时**高度要按这个比例跟着宽度走**：卡片内部是定高分区 + 按宽度
  /// 缩放的字号，高度给错了会挤到溢出。
  static const double designAspectRatio = 1.75;

  /// 导出图（`scale = 1`）里刚好放下内容的卡片高度，雷霆长图直接用它。
  static const double exportCardHeight = 172;

  /// 单卡宽度：`可用宽` 里放 [columns] 张、扣掉 [columnGap] 间隙。
  static double cardWidthFor(
    double availableWidth, {
    int columns = 2,
    double columnGap = 0,
  }) {
    final cols = columns < 1 ? 1 : columns;
    final w = (availableWidth - columnGap) / cols;
    return w <= 0 ? 1 : w;
  }

  /// 字号缩放比例：`单卡宽 / [screenRefCardWidth]`（屏幕口径）。
  ///
  /// 用于**拿不到卡片渲染宽度**的场景（比如按网格外层的宽度估算）。网格
  /// `itemBuilder` 里有紧约束，优先用 [autoScale]（卡片自己量）。
  /// 两种情况都别自己抄 `格子宽 / 335` 或 `格子宽 / 308` —— 抄错不报错，
  /// 只会让字号悄悄不对。
  static double scaleForWidth(
    double availableWidth, {
    int columns = 2,
    double columnGap = 0,
  }) =>
      cardWidthFor(availableWidth, columns: columns, columnGap: columnGap) /
      screenRefCardWidth;

  /// 这个宽度下卡片应该有多高（网格的 `mainAxisExtent` 直接用）。
  static double heightForWidth(
    double availableWidth, {
    int columns = 2,
    double columnGap = 0,
    double aspectRatio = designAspectRatio,
  }) =>
      cardWidthFor(availableWidth, columns: columns, columnGap: columnGap) /
      aspectRatio;

  final Color cardColor;
  final String songName;
  final double achievementRate;
  final double difficulty;
  final bool dxMode;
  final bool isUtage;
  final int score;
  final int maxScore;
  final int rating;
  final String stars;
  final String fc;
  final String fs;
  final String rate;
  final int songId;
  final Color starsColor;
  final int maxIdLength;

  /// 字号缩放。`> 0`：按给定值（导出图片传 `1.0`）；[autoScale]（默认）：
  /// 按卡片**渲染时的实际宽度**自适应。
  final double scale;
  final bool isFitDiff;

  /// 配色。页面传 [B50CardPalette.of]；导出图片不传，取 [ExportThemeScope] 的主题。
  final B50CardPalette? palette;

  const B50GameCardWidget({
    super.key,
    required this.cardColor,
    required this.songName,
    required this.achievementRate,
    required this.difficulty,
    required this.dxMode,
    required this.isUtage,
    required this.score,
    required this.maxScore,
    required this.rating,
    required this.stars,
    required this.fc,
    required this.fs,
    required this.rate,
    required this.songId,
    required this.starsColor,
    required this.maxIdLength,
    this.scale = autoScale,
    this.isFitDiff = false,
    this.palette,
  });

  // ---- 尺寸常量（基于 refCardWidth=335，与导出图片同源）----
  static const double _kSongName = 15.5;
  static const double _kDecimalMain = 30.0;
  static const double _kDecimalSmall = 21.0;
  static const double _kOther = 13.6;
  static const double _kCover = 104.0;
  static const double _kSpacing = 10.0;
  static const double _kStripHeight = 38.0;

  /// 在卡片上**叠**一枚角标（PC50 的 `PC 1234` 就是它）。
  ///
  /// 刻意做成叠层、而不是往卡里塞一个格子：卡片按比例定高，加内容会挤到溢出。
  /// 位置用本组件的设计稿常量，贴在曲绘左下角，不压右边的文字和下方的凹槽。
  static Widget withBadgeOverlay({
    required Widget card,
    required String text,
    double scale = autoScale,
  }) {
    // 角标位置必须和卡片用**同一个** scale：给卡片一个值、给角标另一个值，
    // PC50 角标就会跟曲绘对不上（历史 bug）。
    return LayoutBuilder(
      builder: (context, constraints) {
        final double resolved = resolveScale(scale, constraints.maxWidth);
        return Stack(
          children: [
            card,
            Positioned(
              left: (_kSpacing + 4) * resolved,
              top: (_kSpacing + _kCover - 22) * resolved,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 6 * resolved, vertical: 2 * resolved),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(6 * resolved),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12 * resolved,
                    height: 1.1,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 达成率的「整数段 + 小数段」。
  ///
  /// 两段字号不同（`_kDecimalMain` / `_kDecimalSmall`），**必须画在同一个段落里**
  /// （一个 `Text.rich` + 两个 span）——不要让它们各自成为一句 `Text`。
  ///
  /// ⚠️ **"两句 `Text` + `Row(crossAxisAlignment: baseline)`"就是"有的页面看起来齐、
  /// 有的页面小数偏高"的根源**（6 个 Best50 卡片里恰好只有 2 个是对的）：
  ///
  /// * `Row` 的 baseline 对齐只保证**布局**上基线重合（亚像素级精确）；可两句
  ///   `Text` 是两个 `RenderParagraph`，**各自光栅化、各自吸附像素格**，两段字形
  ///   游程落到不同相位，墨迹底相差 0~3 物理像素。
  /// * 差多少取决于字号落在哪一格：真字体（Google Fonts 的 Noto Sans SC Bold，
  ///   dpr 3.0，按字形墨迹底扫描）实测 `101.0000%`：
  ///
  ///   | 主 / 次字号（dp） | 两段墨迹底之差 |
  ///   |---|---|
  ///   | 18.09 / 13.56 | 0（"齐平"） |
  ///   | 17.90 / 13.43 | −2（小数肉眼可见偏高） |
  ///
  ///   前者正是 `cardW=(W−0.01W)/2` 的 Best50 / 拟合 Best50，后者是另外 4 个页面。
  ///
  /// 换成单个段落（`Text.rich`）后只有一个基线、两段在同一次排版里定位：同一字体
  /// 实测 W=360~430、dpr 2.75 / 3.0、两种卡宽系数、多种亚像素相位下之差**恒为 0**。
  ///
  /// ⚠️ **不要再给小数段叠 `Transform.translate` 做"补偿"**（历史实现就是
  /// 这么写的，那正是"小数严重偏下"的根源）：
  ///
  /// * `RenderTransform` 会把 translate 记进自己的 baseline（`child.getDistanceToBaseline() + offset.dy`），
  ///   但 `RenderFlex` 的 baseline 对齐**实测并不会因此反补偿**——真字体
  ///   （`NotoSansSC_700`，dpr 3.0，按字形墨迹底扫描）测得：`dy` 每变 1 逻辑像素，
  ///   墨迹就跟着平移 1 逻辑像素（1:1，不是 2:1）。
  /// * 于是那笔"补偿"变成了**纯额外的下推量**，得多少就压下去多少
  ///   （scale 1.0 时 +7 物理像素，scale 0.53 时 +3）。
  static Widget _buildAchievement({
    required double achievementRate,
    required double mainFontSize,
    required double subFontSize,
    required Color color,
  }) {
    final text = achievementRate.toStringAsFixed(4);
    final parts = text.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}%' : '%';
    const tabular = [FontFeature.tabularFigures()];

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: intPart,
            style: TextStyle(
              fontSize: mainFontSize,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: tabular,
            ),
          ),
          TextSpan(
            text: decPart,
            style: TextStyle(
              fontSize: subFontSize,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: tabular,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (scale > 0) return _buildCard(context, scale);
    // 默认（[autoScale]）：字号按卡片**渲染时的实际宽度**换算。
    // 网格格子给卡片的是紧约束，`maxWidth` 就是卡片的可见宽度；
    // 页面自己拿屏幕宽度估的值差好几个百分点，会挤出去或留白。
    return LayoutBuilder(
      builder: (context, constraints) =>
          _buildCard(context, resolveScale(scale, constraints.maxWidth)),
    );
  }

  /// [scale] 是**已经解析过**的缩放值（见 [resolveScale]）。
  Widget _buildCard(BuildContext context, double scale) {
    final palette =
        this.palette ?? B50CardPalette.forExport(ExportPalette.of(context));
    final double spacing = _kSpacing * scale;
    final double coverSize = _kCover * scale;
    final double otherFontSize = _kOther * scale;

    // 常规定数保留 1 位小数，拟合定数（fit_diff）保留 2 位以避免丢失精度。
    final String diffText = difficulty.toStringAsFixed(isFitDiff ? 2 : 1);
    final Color pillForeground =
        ThemeData.estimateBrightnessForColor(cardColor) == Brightness.dark
            ? Colors.white
            // 底色是浅色难度色，深色卡片上也要用深色字。
            : B50CardPalette.light.ink;

    // 小卡（页面里 scale < 1）的圆角不跟着缩，否则和周围的卡片对不齐。
    final double radius =
        AppDesignTokens.radiusSmall * (scale < 1 ? 1.0 : scale);
    final double innerRadius = radius * 0.75;
    const tabular = [FontFeature.tabularFigures()];

    final Widget cover = Container(
      width: coverSize,
      height: coverSize,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.strip,
        borderRadius: BorderRadius.circular(innerRadius),
        border: Border.all(color: cardColor, width: 3 * scale),
      ),
      child: songId != 0
          ? CoverUtil.buildCoverWidgetWithContext(
              context, songId.toString(), coverSize)
          : Center(
              child: Text('曲绘',
                  style: TextStyle(
                      fontSize: coverSize * 0.22, color: palette.muted)),
            ),
    );

    // 三个数字按同一条基线对齐，字号不同也不会错位。
    final Widget ratingRow = Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Container(
          padding:
              EdgeInsets.symmetric(horizontal: 7 * scale, vertical: 2 * scale),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(6 * scale),
          ),
          child: Text(
            diffText,
            maxLines: 1,
            style: TextStyle(
              fontSize: otherFontSize,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: pillForeground,
              fontFeatures: tabular,
            ),
          ),
        ),
        SizedBox(width: 6 * scale),
        // RA 字号略大，同基线时看起来偏高，往下挪一点和左右对齐。
        Transform.translate(
          offset: Offset(0, 1.2 * scale),
          child: Text(
            'RA $rating',
            maxLines: 1,
            style: TextStyle(
              fontSize: otherFontSize * 1.1,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: palette.ink,
              fontFeatures: tabular,
            ),
          ),
        ),
        SizedBox(width: 6 * scale),
        Expanded(
          child: Text(
            '$score/$maxScore',
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: otherFontSize * 0.85,
              height: 1.15,
              fontWeight: FontWeight.w600,
              color: palette.muted,
              fontFeatures: tabular,
            ),
          ),
        ),
      ],
    );

    // 歌名最多两行。三段信息撑满曲绘的高度，间距自动均分，
    // 歌名只有一行时上下也不会留出一截空白。
    final Widget info = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          songName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: _kSongName * scale,
            height: 1.22,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _buildAchievement(
              achievementRate: achievementRate,
              mainFontSize: _kDecimalMain * scale,
              subFontSize: _kDecimalSmall * scale,
              color: palette.ink,
            ),
          ),
        ),
        ratingRow,
      ],
    );

    final idStyle = TextStyle(
      fontSize: otherFontSize,
      height: 1.0,
      fontWeight: FontWeight.w700,
      color: palette.muted,
      fontFeatures: tabular,
    );
    final Widget strip = Container(
      height: _kStripHeight * scale,
      padding: EdgeInsets.symmetric(horizontal: 8 * scale),
      decoration: BoxDecoration(
        color: palette.strip,
        borderRadius: BorderRadius.circular(innerRadius),
      ),
      child: Row(
        children: [
          // 谱面 ID（不可见占位保证同一张图里等宽对齐）
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              Opacity(
                opacity: 0,
                child: Text('#${'0' * maxIdLength}', style: idStyle),
              ),
              Text(songId != 0 ? '#$songId' : '', style: idStyle),
            ],
          ),
          SizedBox(width: 5 * scale),
          buildTypeChip(isUtage, dxMode, otherFontSize * 1.05),
          // 六位歌曲 ID 会挤占宽度；右侧信息只在空间不足时等比缩小。
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (rate.isNotEmpty)
                    SizedBox(
                      width: 22 * scale * 110 / 44,
                      height: 22 * scale,
                      child: Image.asset(
                        'assets/gamrank/$rate.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  for (final grade in [fc, fs])
                    Opacity(
                      opacity: grade.isEmpty ? palette.emptyGradeOpacity : 1,
                      child: Image.asset(
                        'assets/grade/${grade.isNotEmpty ? grade : 'empty'}.png',
                        height: 32 * scale,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  // 没有星级时是白色，放在浅色凹槽上看不见，统一用次要文字色
                  buildStarsWidget(
                      stars,
                      starsColor == Colors.white ? palette.muted : starsColor,
                      otherFontSize,
                      heightMultiplier: 1.8),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // 卡片内部全部按宽度缩放，系统字号再叠一层就放不下了。
    return MediaQuery.withNoTextScaling(
      child: Container(
        padding: EdgeInsets.all(spacing),
        decoration: BoxDecoration(
          color: palette.card,
          // 细描边用来在页面底和导出图的底色上勾出卡片的边界。
          border: Border.all(color: palette.border, width: 1.0),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  cover,
                  SizedBox(width: spacing),
                  Expanded(child: SizedBox(height: coverSize, child: info)),
                ],
              ),
            ),
            SizedBox(height: 6 * scale),
            strip,
          ],
        ),
      ),
    );
  }

  /// 类型标签：实心胶囊 + 白字。
  static Widget buildTypeChip(bool isUtage, bool dxMode, double fontSize) {
    final Color background;
    final String text;
    if (isUtage) {
      background = const Color(0xFFD81B3C);
      text = 'UT';
    } else if (dxMode) {
      background = const Color(0xFFC95A12);
      text = 'DX';
    } else {
      background = const Color(0xFF1F4FA5);
      text = 'ST';
    }
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: fontSize * 0.4, vertical: fontSize * 0.14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(fontSize * 0.35),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }

  /// 星数渲染：整数 1-5 用 assets/dxstars/N.png 图片，
  /// 0 / 5.5 / 6 等其他星数用 SizedBox 强制占位为同图片尺寸，保证与有星卡片右边界对齐。
  /// [fontSize] 同时决定图片高度（fontSize * heightMultiplier）与占位尺寸。
  /// dxstars/*.png 实测尺寸 60×36，宽高比 = 5/3。
  /// [compact] 用于前后变化对照：去掉图片左右透明边距和文本等宽占位。
  /// 默认仍保留 B50 卡片需要的固定占位，不改变原有布局。
  static Widget buildStarsWidget(
    String stars,
    Color starsColor,
    double fontSize, {
    double heightMultiplier = 1.8,
    bool compact = false,
  }) {
    const double starsAspect = 5 / 3;
    final match = RegExp(r'✦(\d+(?:\.\d+)?)').firstMatch(stars);
    if (match != null) {
      final n = double.tryParse(match.group(1)!);
      if (n != null && n >= 1 && n <= 5 && n == n.truncateToDouble()) {
        final image = Image.asset(
          'assets/dxstars/${n.toInt()}.png',
          height: fontSize * heightMultiplier,
          fit: BoxFit.contain,
          errorBuilder: (ctx, err, st) => SizedBox(
            width: fontSize * heightMultiplier * starsAspect,
            height: fontSize * heightMultiplier,
            child: Center(
              child: Text(
                stars,
                style: TextStyle(
                  fontSize: fontSize,
                  color: starsColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
        if (!compact) return image;
        // 原图左右透明边距并不一致，按可见像素范围裁切，避免箭头旁出现额外空隙。
        const bounds = {
          1: (left: 20.0, width: 20.0),
          2: (left: 12.0, width: 36.0),
          3: (left: 12.0, width: 36.0),
          4: (left: 8.0, width: 45.0),
          5: (left: 3.0, width: 57.0),
        };
        final crop = bounds[n.toInt()]!;
        return ClipRect(
          child: Align(
            widthFactor: crop.width / 60,
            alignment: Alignment(2 * crop.left / (60 - crop.width) - 1, 0),
            child: image,
          ),
        );
      }
    }
    // ✦0 / ✦5.5 / ✦6 等情况：用占位 SizedBox 保持与有星卡片对齐；
    // Text 用 FittedBox + 大字号自动缩放到与图片星等高，加粗加深可读性。
    // 5.5 / 6 字号比图片星略小一点（1.5x vs 2.0x），避免视觉过重。
    // 5.5 / 6 带深色描边让数字更"立"起来：下层用描边画笔画轮廓，上层画星级色。
    // 不要用多份偏移的 Shadow 拼：字形拐角处会断开，半透明色叠加还会深浅不一。
    // ✦ 与数字拆成 Row 用 baseline 对齐，避免 ✦ 与数字上下错位。
    final bool needsStroke = stars == '✦6' || stars == '✦5.5';
    final String digits = stars.startsWith('✦') ? stars.substring(1) : stars;
    final double textSize = fontSize * 1.5;
    // height=1.0 会把 5.5 / 6 的上下字形和描边压进紧边界，
    // 在部分 dpr 下看起来像上下各缺了一小段黑边。
    final TextStyle baseStyle = TextStyle(
      fontSize: textSize,
      fontWeight: FontWeight.w900,
      height: 1.12,
    );
    Widget starText(String text) {
      final fill = Text(text, style: baseStyle.copyWith(color: starsColor));
      if (!needsStroke) return fill;
      return Stack(
        children: [
          Text(
            text,
            style: baseStyle.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = textSize * 0.16
                ..strokeJoin = StrokeJoin.round
                ..color = const Color(0xFF1F1F1F),
            ),
          ),
          fill,
        ],
      );
    }

    // 给描边留出与字号成比例的上下安全区；固定高度刚好等于图片高度时，
    // 5.5 / 6 的上下阴影会在小卡片和高 dpr 下被父级裁掉。
    final double textBoxHeight = fontSize * (heightMultiplier + 0.35);
    return SizedBox(
      width: compact ? null : fontSize * heightMultiplier * starsAspect,
      height: textBoxHeight,
      child: Center(
        widthFactor: compact ? 1 : null,
        // 紧凑模式只移除多余占位，缩放上限仍与原星数文本一致。
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: compact
                  ? fontSize * heightMultiplier * starsAspect
                  : double.infinity),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: fontSize * 0.08),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  // ✦ 在很多字体里视觉重心偏低，按字号比例轻微上移。
                  Transform.translate(
                    offset: Offset(0, -fontSize * 0.08),
                    child: starText('✦'),
                  ),
                  const SizedBox(width: 1.5),
                  starText(digits),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
