import '../l10n/LocalizationsExtension.dart';
import '../l10n/FeatureLocalizations.dart';
import 'package:flutter/material.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import 'AppUi.dart';

/// 对话框的语气，决定图标和颜色。
enum AppDialogTone { info, success, warning, error }

/// 全 App 对话框的统一外观：左上图标块 + 标题 + 内容 + 等宽按钮。
///
/// 只做外观，不管业务；简单的提示 / 确认 / 进度用下面的 show 系列函数即可。
class AppDialog extends StatelessWidget {
  final String title;
  final Widget? content;
  final IconData? icon;
  final AppDialogTone tone;

  /// 底部按钮，从左到右，每个按钮平分宽度。
  final List<Widget> actions;

  const AppDialog({
    super.key,
    required this.title,
    this.content,
    this.icon,
    this.tone = AppDialogTone.info,
    this.actions = const [],
  });

  static Color toneColor(BuildContext context, AppDialogTone tone) {
    final brightness = Theme.of(context).brightness;
    return switch (tone) {
      AppDialogTone.info => Theme.of(context).colorScheme.primary,
      AppDialogTone.success => AppColors.successGreen(brightness),
      AppDialogTone.warning => AppColors.warningOrange(brightness),
      AppDialogTone.error => Theme.of(context).colorScheme.error,
    };
  }

  static IconData toneIcon(AppDialogTone tone) => switch (tone) {
        AppDialogTone.info => Icons.info_outline_rounded,
        AppDialogTone.success => Icons.check_circle_outline_rounded,
        AppDialogTone.warning => Icons.warning_amber_rounded,
        AppDialogTone.error => Icons.error_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return AppAlertDialog(
      icon: appDialogIconTile(icon ?? toneIcon(tone), toneColor(context, tone)),
      title: Text(title),
      content: content,
      scrollable: true,
      actions: actions,
    );
  }
}

/// 标题左边的图标块。
Widget appDialogIconTile(IconData icon, Color color) => Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      ),
      child: Icon(icon, size: 22, color: color),
    );

/// 与 `AlertDialog` 参数一致的对话框，页面只需换类名，业务逻辑不用动。
///
/// 外观都在这里统一，老页面不用改也能拿到：
/// - 宽度用满（最多 420），标题靠左，按标题的意思带图标块；手写的「图标 + 文字」标题也会拆成同样的结构。
/// - 底部按钮等宽铺满，放不下一行时竖排，文字不再被挤成两行；最后一个确认类按钮是主按钮，删除类用错误色。
/// - 内容里的 ListTile、单选、复选、普通按钮都换成同一套圆角和配色。
class AppAlertDialog extends StatelessWidget {
  final Widget? icon;
  final Widget? title;

  /// 标题下面的一行小字，例如歌名。
  final String? subtitle;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  final bool scrollable;
  final Color? backgroundColor;
  final ShapeBorder? shape;
  final BoxConstraints? constraints;

  /// 底部按钮每行几个，不传时自动决定一行还是竖排。
  final int? actionColumns;

  const AppAlertDialog({
    super.key,
    this.icon,
    this.title,
    this.subtitle,
    this.content,
    this.actions,
    this.contentPadding,
    this.scrollable = false,
    this.backgroundColor,
    this.shape,
    this.constraints,
    this.actionColumns,
  });

  static const _cancelLabels = {
    '取消',
    '关闭',
    '返回',
    '稍后',
    '稍后再说',
    '以后再说',
    '暂不',
    '不了',
    '不用了',
    '继续游戏',
    '關閉',
    '稍後',
    '稍後再說',
    '暫不',
    '繼續遊戲',
    'Cancel',
    'Close',
    'Back',
    'Later',
    'キャンセル',
    '閉じる',
    '戻る',
    '後で',
  };

  static String? _textOf(Widget? widget) {
    if (widget is Text) return widget.data;
    if (widget is Center) return _textOf(widget.child);
    return null;
  }

  /// 按标题的意思选语气。
  static AppDialogTone? _toneOf(String title) {
    if (RegExp('失败|失敗|错误|錯誤|异常|異常|failed|error|エラー', caseSensitive: false)
        .hasMatch(title)) return AppDialogTone.error;
    if (RegExp(
            '删除|刪除|清空|清除|移除|登出|离开|離開|覆盖|覆蓋|重置|重建|delete|clear|sign out|reset|overwrite|削除|ログアウト|上書き',
            caseSensitive: false)
        .hasMatch(title)) {
      return AppDialogTone.warning;
    }
    if (RegExp('成功|完成|已保存|已导出|已匯出|success|complete|saved|exported|完了|保存済み',
            caseSensitive: false)
        .hasMatch(title)) {
      return AppDialogTone.success;
    }
    if (RegExp('提示|确认|说明|注意|权限|版本信息|公告').hasMatch(title)) {
      return AppDialogTone.info;
    }
    return null;
  }

  /// 没有语气的标题（选择器、设置）也按意思给图标；歌名这类动态标题不带。
  static IconData? _iconOf(String title) {
    const rules = <(String, IconData)>[
      ('筛选', Icons.tune_rounded),
      ('排序', Icons.swap_vert_rounded),
      ('设置', Icons.settings_outlined),
      ('规则', Icons.menu_book_outlined),
      ('收藏品', Icons.workspace_premium_outlined),
      ('收藏|下次想玩', Icons.star_outline_rounded),
      ('导出|保存', Icons.ios_share_rounded),
      ('导入', Icons.file_download_outlined),
      ('登录|账号', Icons.person_outline_rounded),
      ('更新|新版本', Icons.system_update_outlined),
      ('笔记|编辑|重命名|新建', Icons.edit_outlined),
      ('添加|加入', Icons.add_rounded),
      ('别名', Icons.sell_outlined),
      ('播放|PV', Icons.play_arrow_rounded),
      ('主题|颜色', Icons.palette_outlined),
      ('同步', Icons.sync_rounded),
      ('选择|移动', Icons.checklist_rounded),
    ];
    for (final (pattern, icon) in rules) {
      if (RegExp(pattern).hasMatch(title)) return icon;
    }
    return null;
  }

  /// 手写标题的颜色只取意思：红 / 绿 / 橙对应语气，其它跟主题色。
  static AppDialogTone? _toneOfColor(Color? color) {
    if (color == null) return null;
    final hsv = HSVColor.fromColor(color);
    if (hsv.saturation < 0.2) return null;
    if (hsv.hue < 20 || hsv.hue > 340) return AppDialogTone.error;
    if (hsv.hue < 60) return AppDialogTone.warning;
    if (hsv.hue >= 80 && hsv.hue < 170) return AppDialogTone.success;
    return null;
  }

  /// 拆开「图标 + 文字」的手写标题；还有别的东西时原样保留。
  static ({Icon icon, Widget text})? _splitRowTitle(Widget? widget) {
    if (widget is! Row) return null;
    Icon? icon;
    Widget? text;
    for (final child in widget.children) {
      final inner = child is Flexible ? child.child : child;
      if (inner is SizedBox && inner.child == null) continue;
      if (inner is Icon && icon == null) {
        icon = inner;
      } else if (inner is Text && text == null) {
        text = inner;
      } else {
        return null;
      }
    }
    return icon == null || text == null ? null : (icon: icon, text: text);
  }

  Widget _buildTitle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w800,
      height: 1.3,
      color: scheme.onSurface,
    );
    final split = _splitRowTitle(title);
    final text = _textOf(split?.text ?? title);
    Widget? leading = icon;
    if (leading is Icon) {
      leading = appDialogIconTile(
          leading.icon!,
          AppDialog.toneColor(
              context, _toneOfColor(leading.color) ?? AppDialogTone.info));
    }
    if (leading == null && split != null) {
      final tone = (text == null ? null : _toneOf(text)) ??
          _toneOfColor(split.icon.color) ??
          AppDialogTone.info;
      leading = appDialogIconTile(
          split.icon.icon!, AppDialog.toneColor(context, tone));
    }
    if (leading == null && text != null) {
      final tone = _toneOf(text);
      final data = tone == null ? _iconOf(text) : AppDialog.toneIcon(tone);
      if (data != null) {
        leading = appDialogIconTile(
            data, AppDialog.toneColor(context, tone ?? AppDialogTone.info));
      }
    }
    // 老代码常把标题包在 Center 里，统一靠左
    Widget body = text != null
        ? Text(text, style: style)
        : DefaultTextStyle.merge(style: style, child: split?.text ?? title!);
    if (subtitle != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          body,
          const SizedBox(height: 2),
          Text(subtitle!,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
        ],
      );
    }
    if (leading == null) return body;
    return Row(
      children: [
        leading,
        const SizedBox(width: 12),
        Expanded(child: body),
      ],
    );
  }

  static Widget? _labelWidget(Widget item) =>
      item is ButtonStyleButton ? item.child : null;

  static bool _isDestructive(Widget item) {
    if (item is! ButtonStyleButton) return false;
    final label = _textOf(_labelWidget(item));
    if (label != null &&
        RegExp('删除|刪除|清空|清除(?!选择|選擇)|移除|登出|覆盖|覆蓋|重置|\\b(delete|clear|sign out|reset|overwrite)\\b|削除|ログアウト|上書き|リセット',
                caseSensitive: false)
            .hasMatch(label)) {
      return true;
    }
    final color = item.style?.foregroundColor?.resolve(const {}) ??
        item.style?.backgroundColor?.resolve(const {});
    return _toneOfColor(color) == AppDialogTone.error;
  }

  Widget _themedAction(BuildContext context, Widget action, bool isPrimary) {
    final scheme = Theme.of(context).colorScheme;
    final Color background;
    final Color foreground;
    if (_isDestructive(action)) {
      background = scheme.errorContainer;
      foreground = scheme.onErrorContainer;
    } else if (isPrimary) {
      background = scheme.primary;
      foreground = scheme.onPrimary;
    } else {
      background = AppSurfaces.inset(context);
      foreground = scheme.onSurface;
    }
    final style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.disabled)
              ? AppSurfaces.inset(context)
              : background),
      foregroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.disabled)
              ? scheme.onSurfaceVariant.withValues(alpha: 0.6)
              : foreground),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      minimumSize: const WidgetStatePropertyAll(Size(0, 46)),
      padding:
          const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
      side: const WidgetStatePropertyAll(BorderSide.none),
      textStyle: WidgetStatePropertyAll(
          AppTheme.font(fontSize: 14, fontWeight: FontWeight.w700)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
      )),
    );
    // 页面给按钮单独写的 style 优先级更高，底部按钮这里统一成同一套。
    final Widget unified = switch (action) {
      TextButton(:final onPressed, :final child) when child != null =>
        TextButton(
            key: action.key, onPressed: onPressed, style: style, child: child),
      FilledButton(:final onPressed, :final child) when child != null =>
        FilledButton(
            key: action.key, onPressed: onPressed, style: style, child: child),
      ElevatedButton(:final onPressed, :final child) when child != null =>
        ElevatedButton(
            key: action.key, onPressed: onPressed, style: style, child: child),
      OutlinedButton(:final onPressed, :final child) when child != null =>
        OutlinedButton(
            key: action.key, onPressed: onPressed, style: style, child: child),
      _ => action,
    };
    return PressScale(scale: 0.97, child: unified);
  }

  Widget _buildActions(
      BuildContext context, List<Widget> items, double availableWidth) {
    // 最后一个不是「取消」的按钮是主按钮
    var primary = -1;
    for (var i = items.length - 1; i >= 0; i--) {
      final item = items[i];
      if (item is ButtonStyleButton &&
          !_cancelLabels.contains(_textOf(item.child))) {
        primary = i;
        break;
      }
    }
    final columns = actionColumns;
    if (columns != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var start = 0; start < items.length; start += columns) ...[
            if (start > 0) const SizedBox(height: 8),
            Row(
              children: [
                for (var i = start;
                    i < start + columns && i < items.length;
                    i++) ...[
                  if (i > start) const SizedBox(width: 8),
                  Expanded(
                      child: _themedAction(context, items[i], i == primary)),
                ],
              ],
            ),
          ],
        ],
      );
    }
    final labels = [for (final item in items) _textOf(_labelWidget(item))];
    final longest = labels.fold<int>(
        0,
        (longest, label) =>
            label != null && label.length > longest ? label.length : longest);
    final buttonWidth =
        (availableWidth - 8 * (items.length - 1)) / items.length;
    final labelStyle = DefaultTextStyle.of(context)
        .style
        .merge(AppTheme.font(fontSize: 14, fontWeight: FontWeight.w700));
    // 按实际字体和系统缩放检查译文宽度，避免日语等短字数文案也被挤换行。
    final labelsTooWide = labels.whereType<String>().any((label) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final tooWide = painter.width + 28 > buttonWidth;
      painter.dispose();
      return tooWide;
    });
    // 放不下就竖排，主按钮在上；不要把「使用默认路径」挤成两行。
    final stacked = (items.length > 1 && labelsTooWide) ||
        items.length > 3 ||
        (items.length == 3 && longest > 3) ||
        (items.length == 2 && longest > 7);
    if (stacked) {
      final order = [
        if (primary >= 0) primary,
        for (var i = 0; i < items.length; i++)
          if (i != primary) i,
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < order.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _themedAction(context, items[order[i]], order[i] == primary),
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _themedAction(context, items[i], i == primary)),
        ],
      ],
    );
  }

  /// 内容区的控件主题：老对话框里的 ListTile、单选、复选不用改也是新样式。
  ThemeData _contentTheme(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return theme.copyWith(
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        horizontalTitleGap: 10,
        minTileHeight: 44,
        minVerticalPadding: 8,
        visualDensity: VisualDensity.compact,
        iconColor: scheme.onSurfaceVariant,
        selectedColor: scheme.primary,
        selectedTileColor: scheme.primary.withValues(alpha: 0.1),
        // ListTile 的样式会整个替换默认文字样式，不带字体就会退回系统字体
        titleTextStyle: AppTheme.font(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface),
        subtitleTextStyle:
            AppTheme.font(fontSize: 12.5, color: scheme.onSurfaceVariant),
      ),
      checkboxTheme: theme.checkboxTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: scheme.outline, width: 1.5),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: AppSurfaces.inset(context),
          foregroundColor: scheme.primary,
          overlayColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = actions ?? const <Widget>[];
    Widget? body = content;
    // 单纯的文字一律可滚动，长说明不会溢出
    if (body != null && (scrollable || body is Text)) {
      body = SingleChildScrollView(child: body);
    }
    return AppDialogEntrance(
      child: Dialog(
        backgroundColor: backgroundColor,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints?.maxWidth ?? 420,
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Semantics(
            scopesRoute: true,
            explicitChildNodes: true,
            namesRoute: true,
            label: _textOf(title) ?? context.featureText('对话框'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _buildTitle(context),
                  ),
                if (body != null)
                  Flexible(
                    child: Padding(
                      padding: contentPadding ??
                          const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Theme(
                        data: _contentTheme(context),
                        child: DefaultTextStyle.merge(
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: scheme.onSurfaceVariant,
                          ),
                          child: body,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, items.isEmpty ? 20 : 18, 20, items.isEmpty ? 0 : 20),
                  child: items.isEmpty
                      ? const SizedBox.shrink()
                      : LayoutBuilder(
                          builder: (context, constraints) => _buildActions(
                              context, items, constraints.maxWidth),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 对话框进场：轻轻上浮并放大。
class AppDialogEntrance extends StatelessWidget {
  final Widget child;

  const AppDialogEntrance({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration:
          AppDesignTokens.motion(context, const Duration(milliseconds: 300)),
      curve: AppDesignTokens.emphasizedCurve,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, (1 - value) * 14),
        child: Transform.scale(scale: 0.95 + 0.05 * value, child: child),
      ),
      child: child,
    );
  }
}

/// 对话框里的一行可点选项：图标、标题、说明。
class AppDialogOption extends StatelessWidget {
  final String title;

  /// 标题行要放标签、跑马灯时用它代替 [title] 的文字。
  final Widget? titleWidget;
  final String? subtitle;

  /// 说明固定一行，放不下时整行等比缩小。
  final bool subtitleSingleLine;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final VoidCallback? onTap;

  const AppDialogOption({
    super.key,
    required this.title,
    this.titleWidget,
    this.subtitle,
    this.subtitleSingleLine = false,
    this.leading,
    this.trailing,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? scheme.primary.withValues(alpha: 0.1)
            : AppSurfaces.inset(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleWidget ??
                    Text(title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: selected ? scheme.primary : scheme.onSurface,
                        )),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  if (subtitleSingleLine)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(subtitle!,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: scheme.onSurfaceVariant)),
                    )
                  else
                    Text(subtitle!,
                        style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: scheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
    if (onTap == null) return tile;
    return PressScale(
      scale: 0.98,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: tile,
      ),
    );
  }
}

/// 对话框内的空状态。
class AppDialogEmpty extends StatelessWidget {
  final IconData icon;
  final String message;

  const AppDialogEmpty({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34, color: scheme.outline),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// 卡片里的凹槽信息块：文件路径、错误详情这类可选中复制的长文本。
class AppDialogCodeBlock extends StatelessWidget {
  final String text;

  const AppDialogCodeBlock(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppSurfaces.inset(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          fontSize: 12,
          height: 1.45,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// 只有一个「确定」的提示。
Future<void> showAppNoticeDialog(
  BuildContext context, {
  required String title,
  required String message,
  AppDialogTone tone = AppDialogTone.info,
  String? confirmLabel,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AppDialog(
      title: title,
      tone: tone,
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(confirmLabel ?? context.l10n.confirm),
        ),
      ],
    ),
  );
}

/// 不可取消的进度提示；由调用方在任务结束后 pop。
Future<void> showAppProgressDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AppDialog(
      title: title,
      icon: Icons.hourglass_top_rounded,
      content: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}
