import 'package:careerspeak_app/application/content_delivery/content_audio_policy.dart';
import 'package:careerspeak_app/application/content_delivery/locale_fallback.dart';
import 'package:careerspeak_app/domain/application_preferences.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('audio role 5 x 5 contract matrix', () {
    final expected = <ContentType, Set<ContentAudioRole>>{
      ContentType.vocabulary: {ContentAudioRole.pronunciation},
      ContentType.phrase: {ContentAudioRole.pronunciation},
      ContentType.interview: {
        ContentAudioRole.question,
        ContentAudioRole.sampleAnswer,
      },
      ContentType.topic: {ContentAudioRole.narration},
      ContentType.shadowing: {ContentAudioRole.shadowing},
    };

    for (final type in ContentType.values) {
      for (final role in ContentAudioRole.values) {
        test('${type.name} x ${role.wireName}', () {
          expect(
            ContentAudioPolicy.allows(type, role),
            expected[type]!.contains(role),
          );
        });
      }

      test('${type.name} primary role is always legal', () {
        expect(
          ContentAudioPolicy.allows(type, ContentAudioPolicy.primaryRole(type)),
          isTrue,
        );
      });

      test('${type.name} required and recommended roles never overlap', () {
        final required = ContentAudioPolicy.requiredRoles(type).toSet();
        final recommended = ContentAudioPolicy.recommendedRoles(type).toSet();
        expect(required.intersection(recommended), isEmpty);
      });
    }
  });

  group('UI locale x translation locale matrix', () {
    for (final uiLocale in AppUiLocale.values) {
      for (final translationLocale in AppTranslationLocale.values) {
        test('${uiLocale.code} x ${translationLocale.code}', () {
          final preferences = ApplicationPreferences.defaults.copyWith(
            uiLocale: uiLocale,
            translationLocale: translationLocale,
          );

          expect(preferences.uiLocale, uiLocale);
          expect(preferences.translationLocale, translationLocale);
          expect(
            preferences.uiLocale.isRtl,
            const {'ar', 'ur', 'fa', 'he'}.contains(uiLocale.languageCode),
          );
        });
      }
    }
  });

  group('backend-owned locale fallback pairwise matrix', () {
    final positive =
        <({String requested, List<String> fallback, List<String> expected})>[
          (
            requested: 'ru-KZ',
            fallback: const ['ru', 'en'],
            expected: const ['ru-KZ', 'ru'],
          ),
          (
            requested: 'kk-KZ',
            fallback: const ['kk', 'ru', 'en'],
            expected: const ['kk-KZ', 'kk', 'ru'],
          ),
          (
            requested: 'pt-BR',
            fallback: const ['en'],
            expected: const ['pt-BR'],
          ),
          (
            requested: 'en',
            fallback: const <String>[],
            expected: const <String>[],
          ),
          (requested: 'ar', fallback: const ['en'], expected: const ['ar']),
        ];

    for (final scenario in positive) {
      test('${scenario.requested} + ${scenario.fallback.join(' > ')}', () {
        final plan = LocaleFallbackPlan(
          requestedLocale: scenario.requested,
          configuredFallbackLocales: scenario.fallback,
        );
        expect(
          plan.localizedCandidates.map((candidate) => candidate.locale),
          scenario.expected,
        );
      });
    }

    final negative = <({String requested, List<String> fallback})>[
      (requested: 'kk-KZ', fallback: const ['kk', 'kk', 'en']),
      (requested: 'ru-KZ', fallback: const ['en', 'ru']),
      (requested: 'not_a_locale', fallback: const ['en']),
      (requested: 'ru', fallback: const ['ru', 'en']),
    ];

    for (final scenario in negative) {
      test('reject ${scenario.requested} + ${scenario.fallback}', () {
        expect(
          () => LocaleFallbackPlan(
            requestedLocale: scenario.requested,
            configuredFallbackLocales: scenario.fallback,
          ),
          throwsFormatException,
        );
      });
    }
  });
}
