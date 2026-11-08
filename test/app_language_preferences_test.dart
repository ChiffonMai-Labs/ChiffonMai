import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_flutter_app/utils/AppLanguagePreferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final preferences = AppLanguagePreferences.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await preferences.reload();
  });

  test('首次使用跟随系统，无法识别的持久化值也回落到跟随系统', () async {
    expect(preferences.language, AppLanguage.system);
    expect(preferences.locale, isNull);
    SharedPreferences.setMockInitialValues({'app_language': 'unknown'});
    await preferences.reload();
    expect(preferences.language, AppLanguage.system);
  });

  test('四种手动语言在重新加载后保持选择', () async {
    for (final language in AppLanguage.values.skip(1)) {
      expect(await preferences.setLanguage(language), isTrue);
      await preferences.reload();
      expect(preferences.language, language);
      expect(preferences.locale, language.locale);
    }
    await preferences.setLanguage(AppLanguage.system);
    await preferences.reload();
    expect(preferences.locale, isNull);
  });

  test('快速连续切换后，内存和持久化都保留最后一次选择', () async {
    await Future.wait([
      preferences.setLanguage(AppLanguage.english),
      preferences.setLanguage(AppLanguage.japanese),
      preferences.setLanguage(AppLanguage.traditionalChinese),
    ]);
    expect(preferences.language, AppLanguage.traditionalChinese);
    await preferences.reload();
    expect(preferences.language, AppLanguage.traditionalChinese);
  });

  test('中文脚本优先，台湾香港澳门区域识别为繁体，未知语言回落到简体', () {
    Locale resolve(List<Locale> locales) =>
        AppLanguagePreferences.resolveLocales(locales, const []);
    const zh = Locale('zh');
    const hant = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
    for (final region in ['TW', 'HK', 'MO']) {
      expect(resolve([Locale('zh', region)]), hant);
    }
    expect(
        resolve([
          const Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hans', countryCode: 'HK')
        ]),
        zh);
    expect(resolve([hant]), hant);
    expect(resolve([const Locale('zh', 'CN')]), zh);
    expect(resolve([const Locale('en', 'GB')]), const Locale('en'));
    expect(resolve([const Locale('ja', 'JP')]), const Locale('ja'));
    expect(
        resolve([const Locale('fr'), const Locale('ja')]), const Locale('ja'));
    expect(resolve([const Locale('fr')]), zh);
    expect(resolve([]), zh);
  });
}
