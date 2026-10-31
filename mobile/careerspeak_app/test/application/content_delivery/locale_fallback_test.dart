import 'package:careerspeak_app/application/content_delivery/locale_fallback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('regional fallback follows configured Backend order', () {
    final plan = LocaleFallbackPlan(
      requestedLocale: 'ru-kz',
      configuredFallbackLocales: const <String>['ru', 'en'],
    );

    expect(plan.requestedLocale, 'ru-KZ');
    expect(
      plan.localizedCandidates.map((candidate) => candidate.locale),
      <String>['ru-KZ', 'ru'],
    );
    expect(plan.localizedCandidates.first.kind, LocaleFallbackKind.exact);
    expect(plan.localizedCandidates.last.kind, LocaleFallbackKind.configured);
  });

  test('Flutter does not invent a base-language fallback', () {
    final plan = LocaleFallbackPlan(requestedLocale: 'ru-KZ');

    expect(
      plan.localizedCandidates.map((candidate) => candidate.locale),
      <String>['ru-KZ'],
    );
  });

  test('Backend may configure a non-derived fallback locale', () {
    final plan = LocaleFallbackPlan(
      requestedLocale: 'ru-KZ',
      configuredFallbackLocales: const <String>['kk', 'en'],
    );

    expect(
      plan.localizedCandidates.map((candidate) => candidate.locale),
      <String>['ru-KZ', 'kk'],
    );
    expect(plan.localizedCandidates.last.kind, LocaleFallbackKind.configured);
  });

  test('language locale checks exact pack before canonical English', () {
    final plan = LocaleFallbackPlan(
      requestedLocale: 'kk',
      configuredFallbackLocales: const <String>['en'],
    );

    expect(plan.requestedLocale, 'kk');
    expect(
      plan.localizedCandidates.map((candidate) => candidate.locale),
      <String>['kk'],
    );
  });

  test('canonical English does not require a locale pack', () {
    final plan = LocaleFallbackPlan(requestedLocale: 'en');

    expect(plan.localizedCandidates, isEmpty);
    expect(LocaleFallbackPlan.canonicalEnglishLocale, 'en');
  });

  test('configured canonical English must be terminal', () {
    expect(
      () => LocaleFallbackPlan(
        requestedLocale: 'ru-KZ',
        configuredFallbackLocales: const <String>['en', 'ru'],
      ),
      throwsFormatException,
    );
  });

  test('invalid locale fails before any storage lookup', () {
    expect(
      () => LocaleFallbackPlan(requestedLocale: 'ru_XX'),
      throwsFormatException,
    );
  });
}
