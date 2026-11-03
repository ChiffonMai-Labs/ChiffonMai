import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/widgets/BackgroundPageScaffold.dart';

import '../../utils/AppDesignTokens.dart';
import '../../widgets/AppUi.dart';

class RoomJoinPage extends StatefulWidget {
  const RoomJoinPage({super.key});

  @override
  State<RoomJoinPage> createState() => _RoomJoinPageState();
}

class _RoomJoinPageState extends State<RoomJoinPage> {
  final TextEditingController _roomIdController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isJoining = false;
  String? _roomIdError;

  static const int _codeLength = 6;

  @override
  void initState() {
    super.initState();
    // 格子的高亮跟着输入框的焦点和内容走
    _focusNode.addListener(_refresh);
    _roomIdController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _roomIdController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleJoin() async {
    if (_isJoining) return;
    String roomId = _roomIdController.text.trim().toLowerCase();

    if (roomId.isEmpty) {
      setState(() => _roomIdError = '房间码不能为空');
      return;
    }

    setState(() => _isJoining = true);

    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) return;
    Navigator.pop(context, roomId);
  }

  void _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    if (data != null && data.text != null) {
      final text = data.text!.trim().toLowerCase();
      setState(() {
        _roomIdController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        _roomIdError = text.isEmpty ? '房间码不能为空' : null;
      });
    }
  }

  /// 6 个格子只负责显示，真正接收输入的是盖在上面的透明输入框。
  /// 粘贴完整房间 ID 时放不进格子，换成一整行显示。
  Widget _buildCodeInput() {
    final scheme = Theme.of(context).colorScheme;
    final text = _roomIdController.text;
    final focused = _focusNode.hasFocus;
    final duration =
        AppDesignTokens.motion(context, AppDesignTokens.fastMotion);
    final digitStyle = AppTheme.number(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    );
    final borderColor = _roomIdError != null ? scheme.error : scheme.primary;

    Widget cell(int index) {
      final active = focused &&
          (index == text.length ||
              (text.length == _codeLength && index == _codeLength - 1));
      return Expanded(
        child: AnimatedContainer(
          duration: duration,
          margin: EdgeInsets.only(left: index == 0 ? 0 : 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppSurfaces.inset(context),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            border: Border.all(
              color: active || (_roomIdError != null && index == text.length)
                  ? borderColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: AnimatedSwitcher(
            duration: duration,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Text(
              index < text.length ? text[index] : '',
              key: ValueKey(index < text.length ? text[index] : ''),
              style: digitStyle,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 60,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: text.length > _codeLength
                ? Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppSurfaces.inset(context),
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusSmall),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(text, maxLines: 1, style: digitStyle),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < _codeLength; i++) cell(i),
                    ],
                  ),
          ),
          Opacity(
            opacity: 0,
            child: TextField(
              controller: _roomIdController,
              focusNode: _focusNode,
              autofocus: true,
              expands: true,
              maxLines: null,
              showCursor: false,
              enableInteractiveSelection: false,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.go,
              // 只限制手动输入；完整房间 ID 通过粘贴按钮写入
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(_codeLength),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
              ),
              onTap: () => _roomIdController.selection = TextSelection.collapsed(
                  offset: _roomIdController.text.length),
              onChanged: (value) {
                final error = value.trim().isEmpty ? '房间码不能为空' : null;
                if (error != _roomIdError) {
                  setState(() => _roomIdError = error);
                }
              },
              onSubmitted: (_) => _handleJoin(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int index, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: TextStyle(
              fontSize: 12,
              height: 1,
              fontWeight: FontWeight.w800,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BackgroundPageScaffold(
      title: '加入房间',
      resizeToAvoidBottomInset: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppDesignTokens.gutter,
          8,
          AppDesignTokens.gutter,
          AppDesignTokens.gutter +
              MediaQuery.paddingOf(context).bottom +
              MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EntranceAnimation(
              offset: const Offset(0, 10),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.meeting_room_rounded,
                            size: 30, color: scheme.primary),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '输入房间码',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '输入 6 位房间码，也支持完整房间 ID',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    _buildCodeInput(),
                    if (_roomIdError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _roomIdError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: scheme.error),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton.icon(
                        onPressed: _handlePaste,
                        icon: const Icon(Icons.content_paste_rounded, size: 16),
                        label: const Text('粘贴房间码'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _isJoining ? null : _handleJoin,
                        child: _isJoining
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: scheme.onPrimary,
                                ),
                              )
                            : const Text(
                                '加入房间',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDesignTokens.cardGap),
            EntranceAnimation(
              index: 1,
              offset: const Offset(0, 10),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '如何获取房间码？',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildStep(1, '房主创建房间后，可在房间页面复制房间码。'),
                    const SizedBox(height: 8),
                    _buildStep(2, '让好友把房间码发给你，在上面粘贴就能加入。'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
