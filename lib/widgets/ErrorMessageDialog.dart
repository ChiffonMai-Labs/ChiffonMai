import 'package:flutter/material.dart';
import 'AppDialogs.dart';

/// 统一的错误信息弹窗。
///
/// 错误详情使用和文件导出结果相同的「主题信息区域 + 可选择文本」样式，
/// 方便长错误、网关返回内容和复制排查信息，不再让错误短暂消失在 Toast 中。
Future<void> showErrorMessageDialog(
  BuildContext context, {
  required String message,
  String title = '操作失败',
}) {
  final text = message.trim().isEmpty ? '未知错误' : message.trim();
  return showDialog<void>(
    context: context,
    builder: (ctx) => AppDialog(
      title: title,
      tone: AppDialogTone.error,
      content: AppDialogCodeBlock(text),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}
