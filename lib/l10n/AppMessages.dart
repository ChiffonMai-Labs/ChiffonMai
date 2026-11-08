import 'package:flutter/widgets.dart';

import '../utils/AppLanguagePreferences.dart';
import 'app_localizations.dart';
import 'FeatureLocalizations.dart';

/// 无 BuildContext 的流程回调取当前语言；界面构建仍优先使用 context.l10n。
AppLocalizations get appL10n {
  final locale = AppLanguagePreferences.instance.locale ??
      AppLanguagePreferences.resolveLocales(
        WidgetsBinding.instance.platformDispatcher.locales,
        AppLocalizations.supportedLocales,
      );
  return lookupAppLocalizations(locale);
}

/// 本地预设标签的显示译文；数据模型、请求参数和存储值保持原样。
String appLocalizeLabel(String label) => localizeFeatureText(appL10n, label);
