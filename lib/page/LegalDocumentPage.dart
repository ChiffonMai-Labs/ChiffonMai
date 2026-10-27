import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:markdown_widget/markdown_widget.dart';

import '../utils/ExternalLaunchUtil.dart';
import '../widgets/BackgroundPageScaffold.dart';

enum AppLegalDocument {
  userAgreement('用户协议', 'user_agreement.md'),
  privacyPolicy('隐私政策', 'privacy_policy.md');

  const AppLegalDocument(this.title, this.fileName);
  final String title;
  final String fileName;
  String get assetPath => 'assets/legal/$fileName';
}

/// 协议随应用发布，首次打开和离线时均可阅读。
class LegalDocumentPage extends StatefulWidget {
  const LegalDocumentPage({super.key, required this.document});
  final AppLegalDocument document;

  static Future<void> open(
      BuildContext context, AppLegalDocument document) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => LegalDocumentPage(document: document),
    ));
  }

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

class _LegalDocumentPageState extends State<LegalDocumentPage> {
  late Future<String> _content;

  @override
  void initState() {
    super.initState();
    _content = rootBundle.loadString(widget.document.assetPath);
  }

  Future<void> _openLink(String value) async {
    for (final document in AppLegalDocument.values) {
      if (value == document.fileName) {
        await LegalDocumentPage.open(context, document);
        return;
      }
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !['https', 'http', 'mailto'].contains(uri.scheme))
      return;
    try {
      if (await ExternalLaunchUtil.open(uri)) return;
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('无法打开链接，请稍后重试')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = theme.brightness == Brightness.dark
        ? MarkdownConfig.darkConfig
        : MarkdownConfig.defaultConfig;
    return BackgroundPageScaffold(
      title: widget.document.title,
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
                        rootBundle.loadString(widget.document.assetPath)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('文档读取失败，点击重试'),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
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
