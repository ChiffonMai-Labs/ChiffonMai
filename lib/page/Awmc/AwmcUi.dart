import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../service/AWMC/AwmcApiService.dart';
import '../../service/AWMC/AwmcStore.dart';
import '../../widgets/PageTopBar.dart';
import '../../widgets/QrQuickFillButtons.dart';

/// AWMC 控制台的公共 UI 组件（结果展示 / 凭据输入 / 写入二次确认）。
///
/// 安全约定：
///   * 结果面板里**没有**「复制」按钮——成绩数据是用户账号数据，
///     随手进剪贴板会被输入法/剪贴板管理器留档；用 SelectableText 让用户自己选。
///   * 令牌与二维码输入框一律 `obscureText` 且不进任何日志。
class AwmcUi {
  AwmcUi._();

  static Color okColor(BuildContext context) => Colors.green.shade600;
  static Color warnColor(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  // ==================== 结果展示 ====================
  /// 抽屉里 businessData 的最大预览字符数（再长就进独立页面看）。
  static const int resultPreviewMaxChars = 4000;

  /// 抽屉里 msg 的最大展示字符数（有的网关会把整页 HTML 塞进 msg）。
  static const int resultMsgMaxChars = 1000;

  /// 弹出调用结果。
  ///
  /// 布局要点（踩过的坑）：**除了固定的头部与底部按钮，其余内容全部放进
  /// 同一个 [SingleChildScrollView]**，且每条文本都限长。
  /// 早先的写法是「Column + 内部固定高度滚动区」，一旦上游返回超长 msg
  /// 或几 MB 的 businessData，非弹性子项会把抽屉撑出十几万像素的溢出。
  static Future<void> showResult(
    BuildContext context,
    AwmcCallResult result, {
    String? title,
  }) {
    final scheme = Theme.of(context).colorScheme;
    // 只序列化一次：既给预览用，也给「查看完整数据」用
    //（拼两次会让几 MB 的 payload 白白编码两遍）
    final fullText = result.businessDataText();
    final hasMoreData =
        result.businessData != null && fullText.length > resultPreviewMaxChars;
    final preview = fullText.length <= resultPreviewMaxChars
        ? fullText
        : '${fullText.substring(0, resultPreviewMaxChars)}…';
    final rawMsg =
        result.msg == null || result.msg!.isEmpty ? null : result.msg!;
    final msgShown = rawMsg == null ? null : AwmcApiService.redact(rawMsg);
    final msgClipped = msgShown != null && msgShown.length > resultMsgMaxChars;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- 固定头部：结论一行可见，不用滚 ----
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Row(
                children: [
                  Icon(
                    result.ok
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    color: result.ok ? okColor(ctx) : warnColor(ctx),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title ?? result.path,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(ctx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            // ---- 可滚动主体：所有行都在同一个滚动容器里 ----
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _kv(ctx, '接口', '${result.method} ${result.path}'),
                    _kv(
                      ctx,
                      '结果',
                      result.ok ? '业务成功' : result.displayMessage,
                      valueColor: result.ok ? okColor(ctx) : warnColor(ctx),
                    ),
                    _kv(ctx, 'HTTP', '${result.httpStatus}'),
                    if (result.returnCode != null)
                      _kv(ctx, 'returnCode', '${result.returnCode}'),
                    if (result.code != null) _kv(ctx, 'code', '${result.code}'),
                    if (msgShown != null)
                      _kv(
                        ctx,
                        'msg',
                        msgClipped
                            ? '${msgShown.substring(0, resultMsgMaxChars)}…'
                            : msgShown,
                        note: msgClipped
                            ? '上游 msg 过长已截断（完整 ${msgShown.length} 字符）'
                            : null,
                      ),
                    _kv(ctx, '耗时', '${result.elapsedMs} ms'),
                    _kv(
                      ctx,
                      '计费',
                      result.billingNote,
                      valueColor: result.ok ? warnColor(ctx) : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'businessData',
                          style: Theme.of(ctx)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        if (result.businessData == null)
                          Text(
                            '（无）',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest
                            .withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      // 不嵌套滚动：让它跟着外层一起滚，长度天然有上限
                      child: SelectableText(
                        preview,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (hasMoreData) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => _AwmcRawDataPage(
                                title: title ?? result.path,
                                text: fullText,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.unfold_more, size: 18),
                        label: const Text('查看完整数据'),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '数据仅在本机展示，不会上传到任何第三方。',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ---- 固定底部按钮：滚多远都能直接关掉 ----
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('关闭'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _kv(
    BuildContext context,
    String key,
    String value, {
    Color? valueColor,
    String? note,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              key,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
                if (note != null)
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 凭据输入 ====================
  /// 通用敏感输入框（令牌 / 二维码 / 第三方密钥）。
  ///
  /// 输入框由对话框自己持有并在 `dispose()` 里释放——**不能**在
  /// `await showDialog()` 返回后立刻 dispose：那时退场动画还在跑，
  /// TextField 仍会引用该 controller（"used after being disposed"）。
  static Future<String?> _askSecret(
    BuildContext context, {
    required String title,
    required String body,
    required String label,
    required String hint,
    String? footer,
    String confirmText = '保存',
    bool multilineWhenVisible = false,
    bool showQrQuickFill = false,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _AwmcSecretDialog(
        title: title,
        body: body,
        label: label,
        hint: hint,
        footer: footer,
        confirmText: confirmText,
        multilineWhenVisible: multilineWhenVisible,
        showQrQuickFill: showQrQuickFill,
      ),
    );
    final trimmed = result?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  /// 输入网关令牌（gw_...）。取消/留空返回 null。
  static Future<String?> askToken(BuildContext context) => _askSecret(
        context,
        title: '设置网关令牌',
        body: '令牌来自 AWMC 控制台（api.wmc.pub），形如 gw_xxxx。\n\n'
            '⚠️ 令牌等同于你的账户操作权限与余额，请勿截图、勿粘贴到聊天/公开仓库。'
            '若怀疑泄露，请立即到控制台吊销并重新生成。',
        label: 'AwmcGateway Token',
        hint: 'gw_...',
        footer: '令牌保存在本机（可随时清除），不会随备份导出。',
      );

  /// 输入机台 qrcode（SGWCMAID...）。取消或格式不对返回 null。
  ///
  /// **每一次需要二维码的操作都会调用它**：不做任何缓存/复用，
  /// 输入的内容只在当次请求里用掉。多端同步时调用方会按目标传入
  /// 不同的 [title] / [body]，提醒用户换一张新的二维码。
  static Future<String?> askQrcode(
    BuildContext context, {
    String title = '输入机台二维码',
    String? body,
  }) async {
    final qrcode = await _askSecret(
      context,
      title: title,
      body: body ??
          '与「同步成绩」用的是同一串二维码内容（SGWCMAID 开头），'
              '可直接从微信/相机识别结果里复制。\n\n'
              '⚠️ 该二维码等同于机台登录凭据，只能用于你自己的账号。',
      label: '二维码内容',
      hint: 'SGWCMAID...',
      footer: '本次输入只用于这一次操作，用完即弃：不保存、不缓存；'
          '下一次操作会重新问你一次。',
      confirmText: '使用',
      multilineWhenVisible: true,
      showQrQuickFill: true,
    );
    if (qrcode == null) return null;
    if (!AwmcCredentials.isValidQrcode(qrcode)) {
      if (context.mounted) {
        Fluttertoast.showToast(msg: '二维码格式不正确（应以 SGWCMAID 开头）');
      }
      return null;
    }
    return qrcode;
  }

  /// 输入第三方平台密钥（水鱼 / 落雪）。只在本次请求里用一次，不落盘。
  static Future<String?> askThirdPartySecret(
    BuildContext context, {
    required String title,
    required String label,
    required String hint,
    required String warning,
  }) =>
      _askSecret(
        context,
        title: title,
        body: warning,
        label: label,
        hint: hint,
        footer: '该密钥只会随本次请求发送给 AWMC 网关转发，不会保存在本机。',
        confirmText: '继续',
      );

  // ==================== 完整数据页 ====================
  /// 完整数据页里单行的最大字符数。
  static const int rawLineMaxChars = 300;

  /// 把整段 JSON 文本切成适合逐行渲染的小块。
  ///
  /// 先按 `\n` 切；仍然超长的行（例如没有换行的长 token / base64）
  /// 再按 [rawLineMaxChars] 硬切——否则会出现「一行几万字符」的段落，
  /// 既卡顿又可能撑爆布局。
  static List<String> splitRawDataForDisplay(String text) {
    final chunks = <String>[];
    for (final line in text.split('\n')) {
      if (line.length <= rawLineMaxChars) {
        chunks.add(line);
        continue;
      }
      for (var i = 0; i < line.length; i += rawLineMaxChars) {
        chunks.add(
            line.substring(i, (i + rawLineMaxChars).clamp(0, line.length)));
      }
    }
    return chunks;
  }

  // ==================== 写入确认 ====================
  /// 写入类操作的统一确认框。
  ///
  /// 必须勾选「我已确认」才能执行——写操作会真实修改机台账号数据，
  /// 且部分操作（删除成绩、清空票券、购票消费 Token）**不可撤销**。
  static Future<bool> confirmWrite(
    BuildContext context, {
    required String title,
    required String path,
    required String summary,
    required int costTokens,
    required bool reversible,
    String? extraWarning,
  }) async {
    var acked = false;
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: scheme.error),
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv(ctx, '接口', 'POST $path'),
                _kv(
                  ctx,
                  'Token 消耗',
                  costTokens > 0 ? '$costTokens（成功才扣）' : '不消耗',
                  valueColor: costTokens > 0 ? scheme.error : null,
                ),
                _kv(
                  ctx,
                  '可撤销',
                  reversible ? '可以（重新上传即可覆盖）' : '不可以',
                  valueColor: reversible ? null : scheme.error,
                ),
                const SizedBox(height: 10),
                Text(summary, style: const TextStyle(fontSize: 13)),
                if (extraWarning != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    extraWarning,
                    style: TextStyle(fontSize: 12.5, color: scheme.error),
                  ),
                ],
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setLocal(() => acked = !acked),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: acked,
                        onChanged: (v) => setLocal(() => acked = v == true),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            '我已确认上述影响，并确认这是我自己账号的二维码',
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: acked ? () => Navigator.pop(ctx, true) : null,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              child: const Text('确认执行'),
            ),
          ],
        ),
      ),
    );
    return confirmed == true;
  }

  // ==================== 小组件 ====================
  /// Token 消耗徽标。
  static Widget costBadge(BuildContext context, int cost) {
    final scheme = Theme.of(context).colorScheme;
    if (cost <= 0) {
      return Text(
        '不计费',
        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
      );
    }
    final high = cost >= 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: high
            ? scheme.errorContainer
            : scheme.surfaceContainerHighest.withValues(alpha: .8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        '$cost Token',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: high ? scheme.onErrorContainer : scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  static Widget riskBadge(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: scheme.onErrorContainer,
        ),
      ),
    );
  }

  /// 控制台分区卡片。
  static Widget section(
    BuildContext context, {
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  /// 分区内的一个动作行（标题 + 副标题 + 计费徽标 + 危险标记）。
  static Widget action({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
    int cost = 0,
    bool danger = false,
    bool enabled = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      enabled: enabled,
      leading: Icon(
        icon,
        size: 20,
        color: !enabled
            ? scheme.onSurfaceVariant
            : (danger ? scheme.error : scheme.primary),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: !enabled ? scheme.onSurfaceVariant : null,
              ),
            ),
          ),
          if (danger) ...[
            riskBadge(context, '写入'),
            const SizedBox(width: 6),
          ],
          costBadge(context, cost),
        ],
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: enabled ? onTap : null,
    );
  }
}

/// 敏感信息输入对话框（令牌 / 二维码 / 第三方密钥）。
///
/// 独立成 StatefulWidget 是为了让 [TextEditingController] 的生命周期
/// 跟对话框一致：在对话框自己的 `dispose()` 里释放，而不是在
/// `await showDialog()` 返回后立刻释放（那时退场动画还在用这个 controller）。
class _AwmcSecretDialog extends StatefulWidget {
  final String title;
  final String body;
  final String label;
  final String hint;
  final String? footer;
  final String confirmText;
  final bool multilineWhenVisible;

  /// 是否显示「读取剪贴板 / 从相册识别 / 扫描二维码」三件套（仅二维码输入用）。
  final bool showQrQuickFill;

  const _AwmcSecretDialog({
    required this.title,
    required this.body,
    required this.label,
    required this.hint,
    this.footer,
    this.confirmText = '保存',
    this.multilineWhenVisible = false,
    this.showQrQuickFill = false,
  });

  @override
  State<_AwmcSecretDialog> createState() => _AwmcSecretDialogState();
}

class _AwmcSecretDialogState extends State<_AwmcSecretDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.body, style: const TextStyle(fontSize: 12.5)),
            if (widget.showQrQuickFill) ...[
              const SizedBox(height: 12),
              // 与水鱼/落雪同步对话框同一套三件套（公共组件）
              QrQuickFillButtons(
                controller: _controller,
                onFilled: () => setState(() {}),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              autofocus: true,
              maxLines: (_obscure || !widget.multilineWhenVisible) ? 1 : 3,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _obscure ? '显示' : '隐藏',
                  icon:
                      Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            if (widget.footer != null) ...[
              const SizedBox(height: 8),
              Text(widget.footer!, style: const TextStyle(fontSize: 11.5)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}

/// 完整数据查看页。
///
/// 上游的 `businessData` 可能有好几 MB（例如整个账号的成绩列表），
/// 一次性塞进一个 `SelectableText` 会构建出超高/超宽的单个段落，
/// 既卡顿又可能撑爆布局。这里按行切片交给 `ListView.builder`：
/// 只渲染可见的那几十行，剩下的按需构建。
class _AwmcRawDataPage extends StatelessWidget {
  final String title;
  final String text;

  const _AwmcRawDataPage({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lines = AwmcUi.splitRawDataForDisplay(text);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // 顶部栏统一走公共组件：标题 = 思源黑体 20 / bold / primary / 居中。
          // 直接用 `appBar: AppBar(title: Text(...))` 时，标题那层裸 `Text`
          // 会被 AppBar 自己的 `DefaultTextStyle` 接管，字体退回系统 Roboto。
          const PageTopBar(title: '完整数据'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            child: Text(
              '$title · 共 ${text.length} 字符 / ${lines.length} 行\n'
              '数据仅在本机展示，不会上传到任何第三方。',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: lines.length,
              itemBuilder: (ctx, i) => SelectableText(
                lines[i],
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
