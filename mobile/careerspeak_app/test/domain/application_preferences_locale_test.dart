import 'package:careerspeak_app/domain/application_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('locale value objects accept and canonicalize BCP-47-compatible values', () {
    expect(AppUiLocale('UZ').code, 'uz');
    expect(AppTranslationLocale('pt-br').code, 'pt-BR');
    expect(AppTranslationLocale('zh-hant-tw').code, 'zh-Hant-TW');
    expect(AppTranslationLocale('es-mx').code, 'es-MX');
  });

  test('locale value objects stay open to future valid locales', () {
    expect(AppTranslationLocale('sw').code, 'sw');
    expect(AppUiLocale('az-Latn-AZ').code, 'az-Latn-AZ');
    expect(AppTranslationLocale.fromCode('not_a_locale'), isNull);
    expect(() => AppUiLocale(''), throwsFormatException);
  });

  test('RTL detection is language based', () {
    expect(AppUiLocale.arabic.isRtl, isTrue);
    expect(AppTranslationLocale.urdu.isRtl, isTrue);
    expect(AppUiLocale('fa-IR').isRtl, isTrue);
    expect(AppUiLocale('he-IL').isRtl, isTrue);
    expect(AppUiLocale.turkish.isRtl, isFalse);
    expect(AppTranslationLocale.uzbek.isRtl, isFalse);
  });

  test('launch qualification catalog includes expanded translation languages', () {
    final codes = AppTranslationLocale.values.map((locale) => locale.code).toSet();

    expect(
      codes,
      containsAll(<String>{
        'en',
        'ru',
        'kk',
        'uz',
        'ky',
        'tr',
        'uk',
        'es',
        'pt-BR',
        'fr',
        'de',
        'ar',
        'ur',
        'hi',
        'bn',
        'id',
        'vi',
      }),
    );
  });
}
