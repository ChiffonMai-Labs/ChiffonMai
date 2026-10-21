import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../service/AWMC/AwmcQuickSyncService.dart';
import '../service/SyncStatsService.dart';
import '../utils/AppTheme.dart';
import 'NoRipple.dart';
import 'QrQuickFillButtons.dart';

/// 各同步表单共用的快速同步选项。绑定安全机台身份后才允许开启。
class QuickSyncOption extends StatefulWidget {
  final Set<SyncPlatform> platforms;
  final ValueChanged<bool> onChanged;
  final int credentialRevision;
  const QuickSyncOption(
      {super.key,
      required this.platforms,
      required this.onChanged,
      this.credentialRevision = 0});
  @override
  State<QuickSyncOption> createState() => _QuickSyncOptionState();
}

class _QuickSyncOptionState extends State<QuickSyncOption> {
  bool _enabled = false;
  bool _ready = false;
  bool _loading = true;
  bool _deleting = false;
  bool _binding = false;
  Map<SyncPlatform, bool> _cached = {};
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(covariant QuickSyncOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!setEquals(oldWidget.platforms, widget.platforms) ||
        oldWidget.credentialRevision != widget.credentialRevision) _check();
  }

  Future<void> _check() async {
    final request = ++_request;
    setState(() => _loading = true);
    final platforms = widget.platforms.toList();
    final ready =
        await Future.wait(platforms.map(AwmcQuickSyncService.hasIdentity));
    if (!mounted || request != _request) return;
    setState(() {
      _loading = false;
      _cached = Map.fromIterables(platforms, ready);
      _ready = ready.isNotEmpty && ready.every((value) => value);
      if (!_ready) _enabled = false;
    });
    widget.onChanged(_enabled);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return NoRipple(
        child: SwitchTheme(
      data: theme.switchTheme.copyWith(
          overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('快速同步'),
            subtitle: Text(_loading
                ? '正在检查用户凭据缓存…'
                : _ready
                    ? '已绑定机台身份，本次无需二维码'
                    : widget.platforms.isEmpty
                        ? '请先选择同步数据源'
                        : '可直接输入二维码绑定机台身份'),
            value: _enabled && !_loading,
            onChanged: _loading || _deleting || !_ready
                ? null
                : (value) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() => _enabled = value);
                    widget.onChanged(value);
                  },
          ),
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Icon(_ready ? Icons.check_circle_outline : Icons.error_outline,
                    size: 16,
                    color: _ready
                        ? AppColors.successGreen(brightness)
                        : AppColors.errorRed(brightness)),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(_ready ? '用户凭据已缓存' : '用户凭据未缓存',
                        style: TextStyle(
                            fontSize: 12,
                            color: _ready
                                ? AppColors.successGreen(brightness)
                                : AppColors.errorRed(brightness)))),
              ]),
            ),
          if (!_loading && !_ready)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _binding ? null : _bindIdentity,
                icon: const Icon(Icons.qr_code_2, size: 18),
                label: Text(_binding ? '正在验证二维码…' : '输入二维码绑定机台身份'),
              ),
            ),
          if (_enabled) ...[
            Text('更新达成率与 DX 分数；连击、同步分别沿用各目标账号现有的标记。暂不更新宴谱和游玩次数。',
                style: Theme.of(context).textTheme.bodySmall),
          ],
          if (!_loading && _cached.values.any((value) => value))
            TextButton(
              onPressed: _deleting
                  ? null
                  : () async {
                      setState(() {
                        _deleting = true;
                        _enabled = false;
                      });
                      widget.onChanged(false);
                      try {
                        await AwmcQuickSyncService.forgetIdentity();
                      } catch (_) {
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('用户凭据删除失败，请重试')));
                      } finally {
                        if (mounted) {
                          await _check();
                          if (mounted) setState(() => _deleting = false);
                        }
                      }
                    },
              child: const Text('删除用户凭据'),
            ),
          if (!_loading && _cached.values.any((value) => value))
            Text('三个数据源共用此凭据，删除时会关闭全部自动同步。',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    ));
  }

  Future<void> _bindIdentity() async {
    final qrCode = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _BindQuickIdentityDialog(),
    );
    if (!mounted || qrCode == null) return;
    setState(() => _binding = true);
    try {
      await AwmcQuickSyncService.bindIdentityWithQr(qrCode);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('机台身份已缓存，现在可以使用快速同步')));
      await _check();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('绑定机台身份失败：$error')));
    } finally {
      if (mounted) setState(() => _binding = false);
    }
  }
}

class _BindQuickIdentityDialog extends StatefulWidget {
  const _BindQuickIdentityDialog();

  @override
  State<_BindQuickIdentityDialog> createState() =>
      _BindQuickIdentityDialogState();
}

class _BindQuickIdentityDialogState extends State<_BindQuickIdentityDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (!value.startsWith('SGWCMAID') || value.length <= 20) {
      setState(() => _error = '请输入有效的 SGWCMAID 机台登入二维码');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('绑定机台身份'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('只读取 userId 用于快速同步，不读取成绩，也不会执行普通同步。'),
              const SizedBox(height: 12),
              QrQuickFillButtons(
                controller: _controller,
                onFilled: () => setState(() => _error = null),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '舞萌DX | 中二节奏登入二维码（SGWCMAID...）',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(onPressed: _submit, child: const Text('验证并缓存')),
        ],
      );
}
