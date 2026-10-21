import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 主题色与纸屑调和色共用同一套调色板，确认后才提交颜色。
Future<Color?> showAppColorPicker(
  BuildContext context, {
  required Color initial,
  String title = '自定义颜色',
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<Color>(
    context: context,
    useSafeArea: true,
    builder: (_) => _ColorPickerDialog(initial: initial, title: title),
  );
}

// ============ 自定义取色器 ============
//
// 不使用固定宽度的第三方取色器，避免窄屏弹窗裁切取色区。
// —— 它的取色区宽度写死 300，在手机 AlertDialog（content ≈ 240dp）里横向溢出，
// 溢出部分摸不到，于是「取色器用不了，只能用预设色」。
//
// 这里的实现只依赖 Flutter 自带的 `HSVColor` + `Gradient`，宽度完全交给父约束，
// 不引入任何硬编码尺寸。

/// `Color` → `#RRGGBB`（不含 alpha；主题 seed 一直是全不透明的）。
String _colorToHex(Color color) {
  final argb = color.toARGB32();
  final rgb = argb & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// `#RGB` / `#RRGGBB` / `#AARRGGBB` → `Color`；非法返回 null。
Color? _parseHexColor(String raw) {
  var hex = raw.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 3) {
    // #abc → #aabbcc
    hex = hex.split('').map((ch) => '$ch$ch').join();
  }
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final value = int.tryParse(hex, radix: 16);
  return value == null ? null : Color(value);
}

/// 十六进制颜色输入框（设置页的"输入十六进制"和取色器弹窗共用）。
///
/// 输入非法时不关弹窗、就地显示错误，避免"点了确定没反应"。
Future<Color?> _showHexInputDialog(BuildContext context, Color fallback) {
  return showDialog<Color>(
    context: context,
    builder: (_) => _HexColorInputDialog(initial: fallback),
  );
}

class _HexColorInputDialog extends StatefulWidget {
  const _HexColorInputDialog({required this.initial});
  final Color initial;

  @override
  State<_HexColorInputDialog> createState() => _HexColorInputDialogState();
}

class _HexColorInputDialogState extends State<_HexColorInputDialog> {
  late final _controller =
      TextEditingController(text: _colorToHex(widget.initial));
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close([Color? color]) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, color);
  }

  void _submit() {
    final value = _parseHexColor(_controller.text);
    if (value == null) {
      setState(() => _error = '格式应为 #RRGGBB 或 #AARRGGBB');
      return;
    }
    _close(value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('输入十六进制颜色'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '#RRGGBB 或 #AARRGGBB',
            errorText: _error,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
            LengthLimitingTextInputFormatter(9),
          ],
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(onPressed: () => _close(), child: const Text('取消')),
          TextButton(onPressed: _submit, child: const Text('确定')),
        ],
      );
}

/// 通用颜色弹窗：取色区 + 色相滑条 + 实时预览 + 十六进制输入。
class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial, required this.title});

  final Color initial;
  final String title;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);

  Color get _color => _hsv.toColor();

  Future<void> _openHexInput() async {
    final picked = await _showHexInputDialog(context, _color);
    if (picked == null || !mounted) return;
    setState(() => _hsv = HSVColor.fromColor(picked));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: scheme.surface,
      title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      content: SizedBox(
        // 让取色区在窄屏上也不会被撑爆；宽度跟着 dialog 走
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _ColorPickerArea(
                    // 测试用的稳定锚点（能直接量尺寸 / 点坐标）
                    key: const ValueKey('color-picker-area'),
                    hsv: _hsv,
                    onChanged: (hsv) => setState(() => _hsv = hsv),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('色相',
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              _HueSlider(
                key: const ValueKey('color-hue-slider'),
                hue: _hsv.hue,
                onChanged: (hue) => setState(
                    () => _hsv = _hsv.withHue(hue.clamp(0.0, 359.999))),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    key: const ValueKey('color-picker-preview'),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _colorToHex(_color),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '拖动上方方块选色，或直接输入十六进制',
                          style: TextStyle(
                              fontSize: 11, color: scheme.onSurfaceVariant),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _openHexInput,
          child: const Text('输入十六进制'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _color),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

/// 取色方块：横轴 = 饱和度，纵轴 = 明度。
///
/// 用两个渐变叠加（白→纯色相 铺满，透明→黑 垂直压暗）得到标准的 SV 面板，
/// 不需要任何自定义 `CustomPainter`。
class _ColorPickerArea extends StatelessWidget {
  const _ColorPickerArea({
    super.key,
    required this.hsv,
    required this.onChanged,
  });

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  void _handle(Offset local, Size size) {
    final s = size.width <= 0 ? 0.0 : (local.dx / size.width).clamp(0.0, 1.0);
    final v =
        size.height <= 0 ? 0.0 : (1.0 - local.dy / size.height).clamp(0.0, 1.0);
    onChanged(hsv.withSaturation(s).withValue(v));
  }

  @override
  Widget build(BuildContext context) {
    final hueOnly = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
    final thumbColor = hsv.toColor();
    final thumbBrightness = ThemeData.estimateBrightnessForColor(thumbColor);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final thumbLeft = (hsv.saturation * size.width).clamp(0.0, size.width);
        final thumbTop =
            ((1 - hsv.value) * size.height).clamp(0.0, size.height);
        return Listener(
          // ⚠️ 取色必须用 `Listener`（原始指针）而不是 `GestureDetector`：
          // 这个取色区在 `SingleChildScrollView` 里，`onTapDown` / `onPanDown`
          // 要等手势竞技场判定（最长 kPressTimeout = 100ms）才会触发 ——
          // 用户"点一下就走"根本取不到色，表现还是"取色器用不了"。
          // 原始指针事件没有竞技场，按下即生效。
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => _handle(e.localPosition, size),
          onPointerMove: (e) => _handle(e.localPosition, size),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, hueOnly],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: thumbLeft - 11,
                top: thumbTop - 11,
                child: IgnorePointer(
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: thumbColor,
                      border: Border.all(
                        color: thumbBrightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 色相滑条（0-360）。
class _HueSlider extends StatelessWidget {
  const _HueSlider({
    super.key,
    required this.hue,
    required this.onChanged,
  });

  final double hue;
  final ValueChanged<double> onChanged;

  static const double _trackHeight = 22;
  static const double _thumbWidth = 14;

  /// 把全局坐标换算成 0-1 的横向比例。
  ///
  /// ⚠️ 同样用 `Listener`（原始指针）而不是 `GestureDetector`：滑条在
  /// `SingleChildScrollView` 里，`onTapDown` 要等竞技场判定才触发，
  /// 用户点一下松手是**取不到色**的（实测：点滑条中点颜色完全不变）。
  ///
  /// 这里用一个 `Builder` 的目的不是省代码：指针事件只给全局坐标，
  /// 要换算成本地比例就得拿到轨道自己的 `RenderBox` —— `LayoutBuilder`
  /// 的 builder context 与轨道 widget 不是同一个节点，量出来的宽度是错的。
  void _handle(BuildContext trackCtx, Offset globalPosition) {
    final box = trackCtx.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 0;
    if (box == null || width <= 0) return;
    final local = box.globalToLocal(globalPosition);
    onChanged((local.dx / width).clamp(0.0, 1.0) * 360);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _trackHeight,
      width: double.infinity,
      child: Builder(
        builder: (trackCtx) => Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => _handle(trackCtx, e.position),
          onPointerMove: (e) => _handle(trackCtx, e.position),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final thumbLeft = (hue / 360 * width - _thumbWidth / 2)
                  .clamp(0.0, (width - _thumbWidth).clamp(0.0, width));
              return Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_trackHeight / 2),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF0000),
                            Color(0xFFFFFF00),
                            Color(0xFF00FF00),
                            Color(0xFF00FFFF),
                            Color(0xFF0000FF),
                            Color(0xFFFF00FF),
                            Color(0xFFFF0000),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: thumbLeft,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: _thumbWidth,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
