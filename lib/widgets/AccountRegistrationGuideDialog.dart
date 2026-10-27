import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../constant/AppLinks.dart';
import '../utils/ExternalLaunchUtil.dart';
import 'GuideLinkText.dart';

Future<void> showAccountRegistrationGuide(BuildContext context) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await showDialog<void>(
    context: context,
    builder: (_) => const _AccountRegistrationGuideDialog(),
  );
}

/// 只展示注册步骤；外链交给系统浏览器，BOT 指令由用户复制后自行发送。
class _AccountRegistrationGuideDialog extends StatelessWidget {
  const _AccountRegistrationGuideDialog();

  Future<void> _openSite(BuildContext context, String url) async {
    if (await ExternalLaunchUtil.openString(url)) return;
    if (context.mounted) await ExternalLaunchUtil.copyFallback(context, url);
  }

  Future<void> _copyCommand(BuildContext context, String command) async {
    await Clipboard.setData(ClipboardData(text: command));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制：$command')),
    );
  }

  Future<void> _copyBotQq(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: AppLinks.awmcBotNumber));
    if (!context.mounted) return;
    Fluttertoast.showToast(msg: '已复制 AWMC BOT QQ 号：${AppLinks.awmcBotNumber}');
  }

  Widget _title(BuildContext context, String text) => Text(text,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w700));

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('账号注册引导'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title(context, '水鱼'),
              const SizedBox(height: 8),
              const GuideLinkText(
                before: '访问 ',
                label: AppLinks.divingFishRegistrationUrl,
                url: AppLinks.divingFishRegistrationUrl,
                after: '，点击右侧“快捷操作”区域的“注册”，随引导操作即可注册水鱼账号。',
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () =>
                    _openSite(context, AppLinks.divingFishRegistrationUrl),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('打开水鱼查分器'),
              ),
              const Divider(height: 24),
              _title(context, '落雪'),
              const SizedBox(height: 8),
              const GuideLinkText(
                before: '访问 ',
                label: AppLinks.luoXueRegistrationUrl,
                url: AppLinks.luoXueRegistrationUrl,
                after: '，点击左侧边栏的“新用户注册”或页面中间处的“注册maimai DX 查分器账号”，'
                    '随引导操作即可注册落雪咖啡屋账号。',
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () =>
                    _openSite(context, AppLinks.luoXueRegistrationUrl),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('打开落雪咖啡屋'),
              ),
              const Divider(height: 24),
              _title(context, 'AWMC NET'),
              const SizedBox(height: 8),
              GuideLinkText(
                before: '私聊 ',
                label: AppLinks.awmcBotName,
                onTap: () => _copyBotQq(context),
                after: '，或在有机器人的群中，依次完成以下步骤：',
              ),
              const SizedBox(height: 8),
              const Text('① 先发送 mymai。'),
              const SizedBox(height: 4),
              Text(
                '尚未建立账号记录时，机器人会回复操作步骤。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              const Text('② 再发送 mai绑定，按提示创建档案。'),
              const SizedBox(height: 8),
              const GuideLinkText(
                before: '加入 ',
                label: AppLinks.awmcGroupOneName,
                url: AppLinks.awmcGroupOneJoinUrl,
                fallbackText: AppLinks.awmcGroupOneNumber,
                fallbackMessage: '无法打开 QQ，已复制 AWMC 交流 1 群的群号，请在 QQ 中搜索加入',
              ),
              const SizedBox(height: 6),
              const GuideLinkText(
                before: '加入 ',
                label: AppLinks.awmcGroupTwoName,
                url: AppLinks.awmcGroupTwoJoinUrl,
                fallbackText: AppLinks.awmcGroupTwoNumber,
                fallbackMessage: '无法打开 QQ，已复制 AWMC 交流 2 群的群号，请在 QQ 中搜索加入',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final command in const ['mymai', 'mai绑定'])
                    OutlinedButton.icon(
                      onPressed: () => _copyCommand(context, command),
                      icon: const Icon(Icons.copy_outlined, size: 16),
                      label: Text('复制 $command'),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      );
}
