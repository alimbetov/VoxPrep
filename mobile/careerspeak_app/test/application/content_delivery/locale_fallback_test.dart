import 'package:careerspeak_app/application/content_delivery/locale_fallback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'regional locale resolves exact then language then canonical English',
    () {
      final plan = LocaleFallbackPlan('ru-kz');

      expect(plan.requestedLocale, 'ru-KZ');
      expect(
        plan.localizedCandidates.map((candidate) => candidate.locale),
        <String>['ru-KZ', 'ru'],
      );
      expect(plan.localizedCandidates.first.kind, LocaleFallbackKind.exact);
      expect(plan.localizedCandidates.last.kind, LocaleFallbackKind.language);
    },
  );

  test('language locale resolves exact then canonical English', () {
    final plan = LocaleFallbackPlan('kk');

    expect(plan.requestedLocale, 'kk');
    expect(
      plan.localizedCandidates.map((candidate) => candidate.locale),
      <String>['kk'],
    );
  });

  test('canonical English does not require a locale pack', () {
    final plan = LocaleFallbackPlan('en');

    expect(plan.localizedCandidates, isEmpty);
    expect(LocaleFallbackPlan.canonicalEnglishLocale, 'en');
  });

  test(
    'regional English may use an exact overlay before canonical English',
    () {
      final plan = LocaleFallbackPlan('en-us');

      expect(plan.requestedLocale, 'en-US');
      expect(
        plan.localizedCandidates.map((candidate) => candidate.locale),
        <String>['en-US'],
      );
      expect(plan.localizedCandidates.single.kind, LocaleFallbackKind.exact);
    },
  );

  test('invalid locale fails before any storage lookup', () {
    expect(() => LocaleFallbackPlan('ru_XX'), throwsFormatException);
  });
}
