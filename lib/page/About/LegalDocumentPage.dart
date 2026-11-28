import 'package:my_first_flutter_app/l10n/FeatureLocalizations.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:markdown_widget/markdown_widget.dart';

import '../../utils/ExternalLaunchUtil.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/AppToast.dart';

import 'package:my_first_flutter_app/widgets/ExpressiveLoadingIndicator.dart';
enum AppLegalDocument {
  userAgreement('用户协议', 'user_agreement.md'),
  privacyPolicy('隐私政策', 'privacy_policy.md');

  const AppLegalDocument(this.title, this.fileName);
  final String title;
  final String fileName;
  String get assetPath => 'assets/legal/$fileName';

  String assetPathForLocale(Locale locale) {
    final suffix = switch(locale.languageCode) {
      'en' => 'en',
      'ja' => 'ja',
      'zh' when locale.scriptCode == 'Hant' => 'zh_Hant',
      _ => null,
    };
    return suffix == null ? assetPath : 'assets/legal/${fileName.replaceFirst('.md', '.$suffix.md')}';
  }
}

/// 协议随应用发布，首次打开和离线时均可阅读。
class LegalDocumentPage extends StatefulWidget {
  const LegalDocumentPage({
    super.key,
    this.document,
    this.customTitle,
    this.customAssetPath,
  }) : assert(
         document != null || (customTitle != null && customAssetPath != null),
       );

  final AppLegalDocument? document;
  final String? customTitle;
  final String? customAssetPath;

  static Future<void> open(
      BuildContext context, AppLegalDocument document) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => LegalDocumentPage(document: document),
    ));
  }

  /// 打开 `assets/legal/` 下的指定离线文档（如开源许可证与第三方声明）。
  static Future<void> openAsset(
    BuildContext context, {
    required String title,
    required String assetPath,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => LegalDocumentPage(
        customTitle: title,
        customAssetPath: assetPath,
      ),
    ));
  }

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

class _LegalDocumentPageState extends State<LegalDocumentPage> {
  late Future<String> _content;
  String _assetPath = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final path = widget.customAssetPath ??
        widget.document!.assetPathForLocale(Localizations.localeOf(context));
    if (_assetPath != path) {
      _assetPath = path;
      _content = rootBundle.loadString(path);
    }
  }

  Future<void> _openLink(String value) async {
    for (final document in AppLegalDocument.values) {
      if (value == document.fileName) {
        await LegalDocumentPage.open(context, document);
        return;
      }
    }
    // 支持离线文档内链跳转至 assets/legal/ 下的 .txt/.md 许可证文本。
    if (!value.contains('://') &&
        !value.contains('..') &&
        (value.endsWith('.txt') || value.endsWith('.md'))) {
      final assetPath =
          value.startsWith('assets/') ? value : 'assets/legal/$value';
      await LegalDocumentPage.openAsset(
        context,
        title: value.split('/').last,
        assetPath: assetPath,
      );
      return;
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !['https', 'http', 'mailto'].contains(uri.scheme))
      return;
    try {
      if (await ExternalLaunchUtil.open(uri)) return;
    } catch (_) {}
    if (mounted) {
      AppToast.show(context.l10n.flowCouldNotOpenTheLinkTryAgain, tone: AppToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = theme.brightness == Brightness.dark
        ? MarkdownConfig.darkConfig
        : MarkdownConfig.defaultConfig;
    final pageTitle = widget.customTitle ??
        context.featureText(widget.document!.title);
    final isPlainText = _assetPath.endsWith('.txt');
    return BackgroundPageScaffold(
      title: pageTitle,
      showDecorativeImage: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: FutureBuilder<String>(
            future: _content,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _content =
                        rootBundle.loadString(_assetPath)),
                    icon: const Icon(Icons.refresh),
                    label:  Text(context.l10n.flowCouldNotLoadDocumentTapToRetry),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: ExpressiveLoadingIndicator.contained(size: 48));
              }
              if (isPlainText) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      20, 12, 20, 24 + MediaQuery.paddingOf(context).bottom),
                  child: SelectableText(
                    snapshot.data!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface,
                      height: 1.6,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              }
              return MarkdownWidget(
                data: snapshot.data!,
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, 24 + MediaQuery.paddingOf(context).bottom),
                config: base.copy(configs: [
                  PConfig(
                      textStyle: theme.textTheme.bodyLarge!
                          .copyWith(color: scheme.onSurface, height: 1.8)),
                  _LegalHeadingConfig('h1',
                      theme.textTheme.headlineSmall!.copyWith(height: 1.4)),
                  _LegalHeadingConfig(
                      'h2',
                      theme.textTheme.titleMedium!
                          .copyWith(fontWeight: FontWeight.w700, height: 1.5)),
                  _LegalHeadingConfig(
                      'h3',
                      theme.textTheme.titleSmall!
                          .copyWith(fontWeight: FontWeight.w600, height: 1.5)),
                  LinkConfig(
                    style: TextStyle(
                        color: scheme.primary,
                        decoration: TextDecoration.underline),
                    onTap: _openLink,
                  ),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 正文标题用留白分节，避免 Markdown 默认分隔线使用固定灰色。
class _LegalHeadingConfig extends HeadingConfig {
  const _LegalHeadingConfig(this.tag, this.style);
  @override
  final String tag;
  @override
  final TextStyle style;
  @override
  EdgeInsets get padding => const EdgeInsets.only(top: 20, bottom: 8);
}
