import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constant/AppLinks.dart';
import '../../l10n/LocalizationsExtension.dart';
import '../../service/Account/AccountDeletionService.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/ExternalLaunchUtil.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/SmoothLinearProgressIndicator.dart';

import 'package:my_first_flutter_app/widgets/ExpressiveLoadingIndicator.dart';
/// 删除 App 内的账号数据。
///
/// 只删 ChiffonMai 本机数据与自家服务端的评论/评分/排行，第三方平台账号保留；
/// 服务端删除是尽力而为，失败项提供邮件申请入口。
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  List<DeletionAccount> _accounts = const [];
  bool _loading = true;
  bool _running = false;
  String _progress = '';
  AccountDeletionReport? _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accounts = await AccountDeletionService.loadAccounts();
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _loading = false;
    });
  }

  Future<void> _start() async {
    if (_running || _accounts.isEmpty) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: l10n.deleteAccountConfirmTitle,
        tone: AppDialogTone.warning,
        icon: Icons.delete_forever_outlined,
        content: Text(l10n.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.flowDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _running = true;
      _report = null;
      _lastAccounts = _accounts.map((e) => e.playerId).toList();
      _progress = l10n.deleteAccountProgressHint;
    });
    try {
      final report = await AccountDeletionService.deleteAll(
        _accounts,
        onProgress: (label) {
          if (!mounted) return;
          setState(() => _progress = label);
        },
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _accounts = const [];
      });
    } catch (error) {
      if (!mounted) return;
      AppToast.show(context.l10n.deleteAccountFailed, tone: AppToastTone.error);
      debugPrint('[DeleteAccount] $error');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _open(Uri uri) async {
    if (await ExternalLaunchUtil.open(uri)) return;
    if (!mounted) return;
    await ExternalLaunchUtil.copyFallback(context, uri.toString());
  }

  Future<void> _email() async {
    final l10n = context.l10n;
    final accounts = _lastAccounts;
    final body = [
      l10n.deleteAccountEmailIntro,
      if (accounts.isNotEmpty) ...accounts,
      if (_report?.failures.isNotEmpty == true) ...[
        '',
        l10n.deleteAccountResultFailures,
        ..._report!.failures,
      ],
      '',
      'App: ChiffonMai',
    ].join('\n');
    final uri = Uri(
      scheme: 'mailto',
      path: AppLinks.supportEmail,
      queryParameters: {
        'subject': l10n.deleteAccountEmailSubject,
        'body': body,
      },
    );
    if (await ExternalLaunchUtil.open(uri)) return;
    await Clipboard.setData(ClipboardData(text: body));
    if (!mounted) return;
    AppToast.show(context.l10n.commentReportCopied);
  }

  /// 完成后账号列表已清空，邮件里仍要带上刚删过的身份。
  List<String> _lastAccounts = const [];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_running,
      child: BackgroundPageScaffold(
        title: l10n.deleteAccountTitle,
        onBack: _running ? () {} : null,
        child: _loading
            ? const Center(child: ExpressiveLoadingIndicator.contained(size: 48))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppDesignTokens.gutter,
                  8,
                  AppDesignTokens.gutter,
                  AppDesignTokens.gutter,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.delete_forever_outlined,
                              color: scheme.error, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.deleteAccountHero,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.55,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.cardGap),
                    if (_running)
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(l10n.deleteAccountProgressTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            const SmoothLinearProgressIndicator(value: null),
                            const SizedBox(height: 10),
                            Text(
                              _progress,
                              style: TextStyle(
                                  fontSize: 12, color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    else if (_report != null)
                      _buildResult(context)
                    else ...[
                      _buildAccountList(context),
                      const SizedBox(height: AppDesignTokens.cardGap),
                      _buildScope(context),
                      const SizedBox(height: AppDesignTokens.cardGap),
                      _buildExternalLinks(context),
                      const SizedBox(height: AppDesignTokens.cardGap),
                      FilledButton.icon(
                        onPressed: _accounts.isEmpty ? null : _start,
                        icon: const Icon(Icons.delete_forever_outlined),
                        label: Text(l10n.deleteAccountButton),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48)),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAccountList(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: context.l10n.deleteAccountAccountsHeader,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 10),
          if (_accounts.isEmpty)
            Text(context.l10n.deleteAccountEmpty,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant))
          else
            for (final account in _accounts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(Icons.account_circle_outlined,
                        size: 20, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${account.source.displayName} · ${account.label}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 8),
          Text(
            context.l10n.deleteAccountBackupHint,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildScope(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(IconData icon, String text, Color color) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text,
                    style: TextStyle(
                        fontSize: 13, height: 1.45, color: scheme.onSurface)),
              ),
            ],
          ),
        );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
              title: context.l10n.deleteAccountWillDelete,
              padding: EdgeInsets.zero),
          const SizedBox(height: 8),
          item(Icons.phone_iphone_rounded, context.l10n.deleteAccountLocal,
              scheme.error),
          item(Icons.cloud_outlined, context.l10n.deleteAccountServer,
              scheme.error),
          item(Icons.autorenew_rounded, context.l10n.deleteAccountAutoSync,
              scheme.error),
          const SizedBox(height: 12),
          AppSectionHeader(
              title: context.l10n.deleteAccountKeep, padding: EdgeInsets.zero),
          const SizedBox(height: 8),
          item(Icons.public_rounded, context.l10n.deleteAccountKeepExternal,
              scheme.primary),
          item(Icons.palette_outlined, context.l10n.deleteAccountKeepLocal,
              scheme.primary),
        ],
      ),
    );
  }

  Widget _buildExternalLinks(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.deleteAccountExternalHint,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TextButton(
                onPressed: () =>
                    _open(Uri.parse(AppLinks.divingFishRegistrationUrl)),
                child: Text(context.l10n.deleteAccountOpenFish),
              ),
              TextButton(
                onPressed: () =>
                    _open(Uri.parse(AppLinks.luoXueRegistrationUrl)),
                child: Text(context.l10n.deleteAccountOpenLxns),
              ),
              TextButton(
                onPressed: () => _open(Uri.parse(AppLinks.awmcNetUrl)),
                child: Text(context.l10n.deleteAccountOpenAwmc),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final report = _report!;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: scheme.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                context.l10n.deleteAccountResultTitle,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.deleteAccountResultCounts(
              report.comments,
              report.ratings,
              report.rankings,
            ),
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
          if (report.hasFailures) ...[
            const SizedBox(height: 12),
            Text(
              context.l10n.deleteAccountResultFailures,
              style: TextStyle(
                  fontSize: 13,
                  color: scheme.error,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            for (final failure in report.failures)
              Text('• $failure',
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _email,
            icon: const Icon(Icons.mail_outline_rounded),
            label: Text(context.l10n.deleteAccountEmailButton),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.deleteAccountDone),
          ),
        ],
      ),
    );
  }
}
